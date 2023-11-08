
target <- chars[[which(names(chars) =="#Hamlet_Ham")]]
source <- chars[[which(names(chars) == "#Ophelia_Ham")]]

all_sim <- list() #list containing all cosine similarity between target sentence and previous source sentences
max_sim <- list() #list containing maximum cosine similarity between a target sentence and previous source sentences
pairsim_sentnces <- list()

for(j in 1:nrow(target)){
for(i in 1:nrow(source)){
  if(source[i,2]<target[j,2]){
    all_sim[[i]] <-cosine(a1[[as.numeric(target[j,2])]], 
                          a1[[as.numeric(source[i,2])]])
  }
  else{ #if there is no previous sentences
    all_sim[[i]] <- 0}
} #end of source loop

pairsim_sentnces[[j]] <- tibble(
  source = unique(source$character),
  target = unique(target$character),
  similarity = max(unlist(all_sim)),
  setnence_num_target = j
)


pairsim_sentnces[[j]]$target_sent <- as.character(target[j,4])
pairsim_sentnces[[j]]$source_sent <- as.character(source[which(all_sim==max(unlist(all_sim))), 4])
}

pairsim_sentnces <- bind_rows(pairsim_sentnces) %>% 
  filter(similarity > 0)

write.csv(as.data.frame(pairsim_sentnces), 
          file = "C:/Users/DELL/Desktop/munka/drama-infoflow/ophelia-hamlet-sentences.csv",
          row.names=FALSE,
          fileEncoding = "UTF-8")

capture.output(as.data.frame(pairsim_sentnces), 
               file = "C:/Users/DELL/Desktop/munka/drama-infoflow/hamlet-ophelia-sentences.csv",
               encoding = "UTF-8")
