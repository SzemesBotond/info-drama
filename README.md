# Measure information flow in dramatic texts
Data from the Shakespeare subcorpus of the Drama Corpus Project: https://github.com/dracor-org/shakedracor

Preprocessing:
1. In folder _drama_conversion_ you can find the steps to create tsv files from the tei files. In the output tsv for every sentence of the drama we assign the name of the speaker, a timestamp, the act in which the sentence is uttered
2. In folder _embedding_test_ you can find the way to calculate embeddings of the sentences created at _drama_conversion_ with any HuggingFace model using HuggingFaceEmbeddings and Sentence-Transformers.

Calculation:
1. In _suprise-pairwise-from-embedding.R_ you can find the main calculations for the pairwise comparison of characters based on the maximum cosine similarities of their sentences taking into account the time of the utterence; the weightening procedure; and the network normalization.
2. In _network-from-embedding.R_ you can find the R codes for visualizing the results from _suprise-pairwise-from-embedding.R_
3. In _pairwise_sentences_ you can compere two characters and see their most and less similar sentences.
