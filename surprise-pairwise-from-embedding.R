library(lsa)
library(tokenizers)
library(dplyr)
library(gtools) #pairwise combinations
#load csv
drama_embedding <- read.csv("C:/Users/DELL/Desktop/munka/drama-infoflow/hamlet_embeddings.csv")

#prerocess the data: 
# - embeddings as numbers
# - instead of timestamp just count the nth position of a sentence
drama_embedding <- drama_embedding %>%
  rowwise() %>%
  mutate(embedding_num = list(reticulate::py_eval(embeddings)))
drama_embedding$created_at <- 1:nrow(drama_embedding)

#save embedding values as numeric in a separate list 
#- we will measure the cosine similarity between the elements of this list
a1 <- lapply(drama_embedding$embedding_num, as.numeric)
# keep the sentences with more than 4 words
tok_sentence <- tokenize_words(drama_embedding$speech_sent)
tok_sentence_length <- sapply(tok_sentence, length)
longsent <- which(tok_sentence_length > 4)
drama_longsent <- drama_embedding[drama_embedding$created_at %in% longsent, ]


# just if not filtered the characters with more than 1000 words
drama_short <- drama_longsent %>%
  filter( character == "#Claudius_Ham" | character == "#Gertrude_Ham" | 
            character =="#Hamlet_Ham" | character == "#Horatio_Ham" | 
            character == "#Laertes_Ham" | character == "#Ophelia_Ham" | 
            character == "#Polonius_Ham")

# castlist
cast <- sort(unique(drama_short$character))

#  sentences of a character in separate tibble
chars <- drama_short %>% 
  group_by(character)
chars <- group_split(chars)
names(chars) <- cast

# get all the possible pairwise combinations of char names
pairs <-as.data.frame(permutations(length(cast), 2, cast, repeats = FALSE))
colnames(pairs) <- c("source", "target")

## main calculation of the semantically closest sentences between S(ource) and T(arget)

#list for the tibbles of the pairwise measures
pair_sim <- list()
# loop iterates over the pairs (firs column = source, second = target)
for(k in 1:nrow(pairs)){
  source <- chars[[which(names(chars) == pairs[k,1])]]
  target <- chars[[which(names(chars) == pairs[k,2])]]
  
  all_sim <- list() #list containing all cosine similarity between target sentence and previous source sentences
  max_sim <- list() #list containing maximum cosine similarity between a target sentence and previous source sentences
  
  #loop ove the target sentences
  for(j in 1:nrow(target)){
    #loop over source sentences
    for(i in 1:nrow(source)){
      if(source[i,2]<target[j,2]){
        all_sim[[i]] <-cosine(a1[[as.numeric(target[j,2])]], 
                              a1[[as.numeric(source[i,2])]])
      }
      else{ #if there is no previous sentences
        all_sim[[i]] <- 0}
    } #end of source loop
    max_sim[[j]] <- max(unlist(all_sim)) #the maximum of the calculated similarities
  }#end of target loop
  target$max_sim <- unlist(max_sim) 
  target1 <- target %>% filter(max_sim > 0)
  # add weight by act (the diff between act_mean and all_mean)
  # "diff" from effect_linear-correlation-time.R
  
  max_sim <- list()
  for(l in 1:nrow(target1)){  
    if (as.numeric(target1[l,2]) %in%  as.numeric(act_length[1,3]):as.numeric(act_length[2,3])){
      max_sim[[l]] <- target1[l,8] + diff[[1]] } # 8th column if ACT is added before
    
    if (as.numeric(target1[l,2]) %in%  as.numeric(act_length[2,3]):as.numeric(act_length[3,3])){
      max_sim[[l]] <- target1[l,8] + diff[[2]] }
    
    if (as.numeric(target1[l,2]) %in%  as.numeric(act_length[3,3]):as.numeric(act_length[4,3])){
      max_sim[[l]] <- target1[l,8] + diff[[3]] }
    
    if (as.numeric(target1[l,2]) %in%  as.numeric(act_length[4,3]):as.numeric(act_length[5,3])){
      max_sim[[l]] <- target1[l,8] + diff[[4]] }
    
    if (as.numeric(target1[l,2]) %in%  as.numeric(act_length[5,3]):as.numeric(act_length[6,3])){
      max_sim[[l]] <- target1[l,8] + diff[[5]] }
  }
  
  pair_sim [[k]] <- tibble(
    source = pairs[k,1],
    target = pairs[k,2],
    flow = mean(unlist(max_sim))
  ) #end of pairs loop 
}

# summarise everything in one tibble
pairwise_flow <- bind_rows(pair_sim)

# add network normalization to the flow between two chars:
#first calculate all flow to one char as target, than divide the actual measure when this char is a source

# all flow to one char
flow_to_char <- pairwise_flow %>% 
  group_by(target) %>% 
  group_split()

flow_to_char1 <- list()
for (i in 1:length(flow_to_char)){
  flow_to_char1[[i]] <- mean(flow_to_char[[i]]$flow)}

flow_to_all <- tibble(flow_to = unlist(flow_to_char1), char = names(chars))

#add to dataframe and divide the flow when char is source
pairwise_weigthed <- merge(pairwise_flow, flow_to_all, by.x = "source", by.y = "char")
pairwise_weigthed <- pairwise_weigthed %>% 
  mutate(weigthed_flow = flow/flow_to)

## calculate difference beetween S-T T-S pairs
pair_diff <- list()
for (i in 1:nrow(pairwise_weigthed)){
  for( j in 1:nrow(pairwise_weigthed)){
    if (pairwise_weigthed[i,1] == pairwise_weigthed[j,2] & pairwise_weigthed[j,1] == pairwise_weigthed[i,2]){
      pair_diff [[i]] <-
        tibble(
          source = pairwise_weigthed[i,1],
          target = pairwise_weigthed[i,2],
          flow_w = pairwise_weigthed[i,5]-pairwise_weigthed[j,5],
          flow = pairwise_weigthed[i,3]-pairwise_weigthed[j,3]
        )}}}

pair_diff <- bind_rows(pair_diff)
pair_diff <- pair_diff %>% 
  filter(flow > 0)
colnames(pair_diff) <- c("source", "target", "flow_w", "flow")

#save results
capture.output(as.data.frame(pair_diff), file = "pairwise-cosine-longsentence-wiegtbyact.csv")

## correlation between number of long sentences and information value
# how similar to other's previous sententeces: flow_to
flow_to_all$sentence_num <-  as.numeric(sapply(chars,nrow))
cor(flow_to_all$sentence_num, flow_to_all$flow_to) #-0.66
# Claudius is not informative compare how many long sentence he says;
# Laertes is more informative compare how many long sentence he says
# not deterministic, but more chance to say something new, if sbdy speaks more