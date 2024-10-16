#"act_mean_sim" and "drama_embedding" tibble from "max-sim-from-embedding.R"
sims = drama_embedding %>% 
  cross_join(drama_embedding) %>%
  filter(row.x > row.y) %>%
  rowwise() %>%
  filter(row.x != row.y) %>% 
  mutate(cosine_similarity = unlist(embedding_num.x) %*% unlist(embedding_num.y))

pair <- sims %>% 
  filter(character.x == "#Othello_Oth") %>% 
  filter(character.y == "#Emilia_Oth")

pair_max <- pair %>% 
  group_by(row.x) %>% 
  mutate(max_score =max(cosine_similarity)) %>% 
  filter(cosine_similarity == max_score) %>% 
  select(row.x, character.x, sentence.x, max_score, character.y, sentence.y, row.y, act_number.x)


pair_max_weight <- pair_max %>% 
  left_join(act_mean_sim, by = "act_number.x") %>%
  mutate(weighted_max_sim = max_score + act_diff) %>% 
  select(row.x, character.x, sentence.x, weighted_max_sim, character.y, sentence.y, row.y, act_number.x)


pair_max_weight <- arrange(pair_max_weight, desc(weighted_max_sim)) #or not desc

# 5-10% of the data (max and min)
target_percent <- round(nrow(pair_max_weight)*0.05) 
target_max <-pair_max_weight[1:target_percent,]
target_min <- pair_max_weight[(nrow(pair_max_weight)-target_percent):nrow(pair_max_weight),]

