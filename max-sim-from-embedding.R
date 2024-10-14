library(dplyr)
library(readr)

# 1. preprocesing data
drama_embedding <- read_tsv('C:/Users/DELL/Desktop/munka/drama-infoflow/info-drama/embeddings_tests/embedding_outputs/hamlet-name_all-MiniLM-L6-v2.tsv') %>% 
  rowwise() %>%  
  mutate(embedding_num = embedding %>%  jsonlite::parse_json() %>%  list()) %>% 
  select(-embedding) %>%  ungroup() %>% 
  mutate(row = 1:n()) %>%  rowwise() %>%  
  mutate(embedding_num = embedding_num %>%  unlist() %>%  (function(x) {x/sum(x^2)})() %>% list() ) %>% 
  mutate(token_length = tokenizers::count_words(sentence))  %>% 
  filter(token_length > 4) %>% 
  group_by(character) %>% 
  filter(n() >= 50) %>% # based on the length of the play
  ungroup() # here possibly filter characters manually, like: filter(character != "#Gravedigger_Ham")
  # or "#DukeFrederick_AYL", "#Oliver_AYL", "#Corin_AYL"

unique(drama_embedding$character)

# 2. Infos about the acts to normalization
# Calculate cosine similarity between sentences
sims = drama_embedding %>% 
  cross_join(drama_embedding) %>%
  filter(row.x > row.y) %>%
  rowwise() %>% 
  mutate(cosine_similarity = unlist(embedding_num.x) %*% unlist(embedding_num.y)) %>% 
  group_by(row.x, act_number.x) %>%  
  summarize(max_sim=max(cosine_similarity)) 

# Calculate the mean of the max sims
all_mean_sim <- mean(sims$max_sim)

# Calculate the mean of the max sims in an act  
act_mean_sim <- sims %>% 
  group_by(act_number.x) %>% 
  summarise(mean = mean(max_sim)) %>% 
  mutate(act_diff = all_mean_sim - mean)

# 3. Main calculation - pairwise similarities
sims1 = drama_embedding %>% 
  cross_join(drama_embedding) %>%
  filter(row.x > row.y) %>%
  rowwise() %>% 
  filter(character.x != character.y) %>% 
  rowwise() %>% 
  mutate(cosine_similarity = unlist(embedding_num.x) %*% unlist(embedding_num.y)) %>% 
  group_by(row.x, character.x, character.y, act_number.x ) %>%  
  summarize(max_sim=max(cosine_similarity)) %>% 
  left_join(act_mean_sim, by = "act_number.x") %>%
  mutate(weighted_max_sim = max_sim + act_diff)

# Calculate pairwise relations between characters based on weighted max sim scores
pairwise_summary <- sims1 %>% 
  group_by(character.y, character.x)  %>%   
  summarize(mean_score = mean(weighted_max_sim))

# Add 0 to a pair, where there is no previous sentences in a target-source comparision
# First calculate all  character pairs
character_pairs = drama_embedding %>%
  cross_join(drama_embedding) %>% 
  filter(character.x != character.y) %>% 
  distinct(character.x, character.y)

missing_combinations <- character_pairs %>%
  anti_join(pairwise_summary, by = c("character.x", "character.y")) %>% 
  mutate(mean_score = 0)

# Combine the new rows with the original 'pairwise_summary'
pairwise_summary <- pairwise_summary %>%
  bind_rows(missing_combinations)


# 4. Network normalization
# Summarize target mean weighted max scores
# "character.x" is the target
target_means <- pairwise_summary %>% 
  group_by(character.x) %>% 
  summarise(mean_target = mean(mean_score))

pairwise_norm <-  pairwise_summary %>%
  left_join(target_means, by = c("character.y" = "character.x")) %>% 
  mutate(norm_score = mean_score/mean_target)

pairwise_norm_diff <- pairwise_norm %>%
  inner_join(pairwise_norm, 
             by = c("character.x" = "character.y", "character.y" = "character.x"), 
             suffix = c(".1", ".2")) %>%
  mutate(norm_score_diff = norm_score.1 - norm_score.2) %>%
  mutate(mean_score_diff = mean_score.1 - mean_score.2) %>%
  select( character.y = character.y, character.x = character.x, norm_score_diff, mean_score_diff) %>% 
  filter(norm_score_diff > 0) 
# or mean_score_diff > 0 is better, if a characters speaks just 
# in the beginning, and its sentences are always before than other chars.
# Like Brabantino in Othello

