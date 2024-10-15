# Measure information flow in dramatic texts
Data from the Shakespeare subcorpus of the Drama Corpus Project: https://github.com/dracor-org/shakedracor

Preprocessing:
1. In folder _drama_conversion_ you can find the steps to create tsv files from the tei files. In the output tsv for every sentence of the drama we assign the name of the speaker, a timestamp, the act in which the sentence is uttered
2. In folder _embedding_test_ you can find the way to calculate embeddings of the sentences created at _drama_conversion_ with any HuggingFace model using HuggingFaceEmbeddings and Sentence-Transformers.

Calculation:

Perform the comparison on the pre-processed data (see "hamlet-name_all-MiniLM-L6-v2.tsv" as an example) using "max-sim-from-embedding.R" The steps described in our article "Innovation and Repetition in Dramatic Texts" (doi: 10.26083/tuprints-00027395) are followed, see Method section. 

The first step involves data filtering (retaining sentences with more than 4 words and characters with an exact number of utterances). The second step computes the average Maximum Cosine Similarity (MCS) score for a play and its acts. Step 3 is the main calculation by comparing the characters' sentences pairwise (and by normalizing the results based on the acts in which the sentences are uttered). Step 4 is the network normalization of the results. The final tibble named "pairwise_norm_diff" can be used as input to the network visualization using "networfk-from-embedding.R".

Examples:

In folder "sentence-example" you can find examples of the results of some plays. You can find here the most and least similar sentences in the pairwise comparisoins. In the subfolder "model-compare" you can find preselected sentences ("sentences-to-compare.txt") and their similarities based on different models (in the .csv files)


Many thanks for Benjamin Schmidt and Malte Vogel in reviewing the R codes under the Community Code Review project (https://dhcodereview.github.io/)
