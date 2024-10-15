drama_embedding <- read_tsv('YOUR_DIR/hamlet-name_all-MiniLM-L6-v2.tsv') %>% 
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


sims = drama_embedding %>% 
  cross_join(drama_embedding) %>%
  filter(row.x > row.y) %>%
  rowwise() %>% 
  mutate(cosine_similarity = unlist(embedding_num.x) %*% unlist(embedding_num.y))

sims1 <- sims %>% 
  group_by(row.x, act_number.x) %>%  
  summarize(max_sim=max(cosine_similarity)) 

# Calculate the mean of the max sims
all_mean_sim <- mean(sims1$max_sim)

# Calculate the mean of the max sims in an act  
act_mean_sim <- sims1 %>% 
  group_by(act_number.x) %>% 
  summarise(mean = mean(max_sim)) %>% 
  mutate(act_diff = all_mean_sim - mean)

sims2 <- sims %>% 
  left_join(act_mean_sim, by = "act_number.x") %>%
  mutate(weighted_max_sim = cosine_similarity + act_diff)

hamlet <- sims2 %>% filter(character.x =="#Hamlet_Ham")%>%  
  filter(character.y!="#Hamlet_Ham") %>% 
  select(sentence.x, character.x, character.y, weighted_max_sim, cosine_similarity)

hamlet_cos <- arrange(hamlet, desc(cosine_similarity))

# 1% of the data
hamlet_percent <- round(nrow(hamlet_cos)*0.01) 
hamlet_min <- hamlet_cos[1:hamlet_percent,]
hamlet_min_deduplicated_sentences <- hamlet_min %>% 
  distinct(sentence.x, .keep_all = TRUE)

