# Embeddings testing

## Set up
Install virtual environment
<br>`python3 -m venv venv`
<br> Activate virtual environment
<br>`python3 -m venv venv`
<br>Mac/Linux
<br>`source venv/bin/activate`
<br>Windows
<br>`venv\Scripts\activate`
<br>Install dependencies
<br>`pip install -r requirements.txt`
<br>

## Run
<br>Calculate embeddings from Drama sentence split TSV with any HuggingFace model using HuggingFaceEmbeddings and Sentence-Transformers. 
<br>`python embeddings_from_drama_tsv.py path/to/drama.tsv "user/modelname"`