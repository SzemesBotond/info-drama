a1 <- lapply(drama_longsent$embedding_num, as.numeric)
all_together <- list()
max_together <- list()
for(i in 1:length(a1)){ 
    for(j in 1:length(a1)){
      if(j<i){    
        all_together [[j]] <- cosine(a1[[i]], a1[[j]] )}
      else{
        all_together [[j]] <- 0}
      }
  max_together[[i]] <- max(unlist(all_together)) }

together <-  c()
together <-  tibble ( sentence_num = 1:length(max_together), 
                      similarity_score = unlist(max_together))

ggplot(together, aes ( x = sentence_num, y = similarity_score))+
  geom_point(alpha = 0.2)+
  geom_smooth(method= "lm", color = "red")+
  theme_bw()

fit <- lm(together$sentence_num ~ together$similarity_score )
summary(fit)

## Weigth by acts

# mena of all the max cosine similarity
all_mean <- mean(unlist(max_together))

# calculate means by act

act_length <- drama_longsent %>% 
  group_by(act) %>% 
  count() 
act_length$pos <- cumsum(act_length$n)
act_length <- bind_rows(
          tibble(act = "Beggining", n= 1, pos = 1 ),
          act_length)

act_mean <- list()
for(i in 1:nrow(act_length)){
  if ( i < nrow(act_length)){
    act_mean [[i]] <- mean(unlist(
      max_together[as.numeric(act_length[i,3]):as.numeric(act_length[i+1,3])] ) ) } }

diff <- all_mean - unlist(act_mean)

# add weight to the model
a1 <- lapply(drama_longsent$embedding_num, as.numeric)
all_together <- list()
max_together <- list()
for(i in 1:length(a1)){ 
  for(j in 1:length(a1)){
    if(j<i){    
      all_together [[j]] <- cosine(a1[[i]], a1[[j]] )}
    else{
      all_together [[j]] <- 0}
  }
  max_together[[i]] <- max(unlist(all_together)) 
  
  # add weigth by act (the diff beetween act_mean and all_mean)
  if (i %in%  as.numeric(act_length[1,3]):as.numeric(act_length[2,3])){
    max_together[[i]] <- max_together[[i]] + diff[[1]] }
  
  if (i %in%  as.numeric(act_length[2,3]):as.numeric(act_length[3,3])){
    max_together[[i]] <- max_together[[i]] + diff[[2]] }
  
  if (i %in%  as.numeric(act_length[3,3]):as.numeric(act_length[4,3])){
    max_together[[i]] <- max_together[[i]] + diff[[3]] }
  
  if (i %in%  as.numeric(act_length[4,3]):as.numeric(act_length[5,3])){
    max_together[[i]] <- max_together[[i]] + diff[[4]] }
  
  if (i %in%  as.numeric(act_length[5,3]):as.numeric(act_length[6,3])){
    max_together[[i]] <- max_together[[i]] + diff[[5]] }
}


#all sentences
acts <- c( rep ("ACT-1", 532),
           rep ("ACT-2", 415),
           rep ("ACT-3", 556),
           rep ("ACT-4", 396),
           rep ("ACT-5", 510) )

drama_embedding$act <- acts

act_pos <- list(1:532, 533:947, 948:1503, 1504:1899, 1900:2409)
