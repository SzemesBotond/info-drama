library(ggraph)
library(igraph)
library(dplyr)
library(tidyverse)

#data from max-sim-from-embedding.R, final tibble called "pairwise_norm_diff"
# create df for EDGES
tbl_links <- pairwise_norm_diff
colnames(tbl_links) <- c("from", "to", "flow_weight", "flow")
#clean character names
tbl_links$from <- gsub("\\#", "", 
                       gsub("_.*", "", tbl_links$from))
tbl_links$to <- gsub("\\#", "", 
                     gsub("_.*", "", tbl_links$to))

#create df for NODES (character names)
tbl_nodes <- data.frame(unique(tbl_links[1]))
colnames(tbl_nodes) <- "names"

# add weigth to NODES based on the number of being a Source in the comparisons
char_weigth <- table(tbl_links$from)
char_weigth <- tibble(degree = char_weigth, names = names(char_weigth))

tbl_nodes <- full_join(tbl_nodes, char_weigth)
tbl_nodes <- tbl_nodes %>% 
  replace(is.na(.), 0.5) # adds 0.5 to the Node which is never a Source in the final comparison

#make the graph
graph <- graph_from_data_frame(tbl_links, tbl_nodes, directed = TRUE)

#visualize with Fruchterman-Reingold layout

p <- ggraph(graph, layout = "fr") +
  geom_edge_link(aes(edge_alpha = flow_weight,
                     width = flow_weight),
                 arrow = arrow(length = unit(3, 'mm')), 
                 end_cap = circle(3, 'mm'),
                 check_overlap = TRUE) +
  geom_node_point(aes(size = degree, color = "red"))+
  scale_color_brewer(palette="Set1") +
  scale_label_size(range = c(10,6))+
  scale_edge_width(range = c(1, 1.5))+
  theme_void()+
  theme(legend.position = "none")

p + geom_node_label(aes(label = tbl_nodes$names,
                        color = "red", family= "Script"), 
                    repel = TRUE,
                    nudge_x = p$data$x * -(.03),
                    nudge_y = p$data$y * -(.05))


#visualize with Forca-Atlas2 layout

library(ForceAtlas2)
data <- tbl_links[,1:3]
colnames(data[,3]) <- "wieght"
layout <- layout.forceatlas2(data, directed=FALSE, iterations = 2000, plotstep = 100)
colnames(layout) <- c("names", "x", "y")

play_structure <- ggraph(graph, layout = layout) +
  geom_edge_link(aes(edge_alpha = flow_weight,
                     width = flow_weight),
                 arrow = arrow(length = unit(3, 'mm')), 
                 end_cap = circle(3, 'mm'),
                 check_overlap = TRUE) +
  geom_node_point(aes(size = degree, color = "red"))+
  scale_color_brewer(palette="Set1") +
  scale_label_size(range = c(10,6))+
  scale_edge_width(range = c(1, 1.5))+
  theme_void()+
  theme(legend.position = "none")

play_names <- 
  ggraph(graph, layout=layout) +  # Using 'fr' layout for force-directed placement
    geom_node_label(aes(label = name,  color = "red", family= "Script", 
                        size = 10)) +
    theme_void()+
  theme(plot.margin = margin(20, 20, 10, 20))+
  theme(legend.position = "none")
