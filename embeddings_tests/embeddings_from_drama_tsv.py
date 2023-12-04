import argparse
from pathlib import Path

import pandas as pd

from langchain.embeddings import HuggingFaceEmbeddings, SentenceTransformerEmbeddings


DIR_PATH = Path(__file__).resolve().parent
CSV_OUTPUTS_DIR = DIR_PATH / 'embedding_outputs'
if not CSV_OUTPUTS_DIR.is_dir():
    CSV_OUTPUTS_DIR.mkdir(parents=True, exist_ok=True)


def main():
    parser = argparse.ArgumentParser()
    parser.add_argument('drama_tsv',
                        help='TSV file of drama created from TEI. '
                             'Required columns are: sentence, created_at, character, act_number')
    parser.add_argument('model', help='model form HuggingFace to use. e.g. sentence-transformers/all-MiniLM-L6-v2')
    args = parser.parse_args()
    df = pd.read_csv(args.drama_tsv, sep='\t')

    # Model choice
    embedder = HuggingFaceEmbeddings(model_name=args.model)
    df['embedding'] = embedder.embed_documents(df['sentence'])

    out_filename = f'{Path(args.drama_tsv).stem}_{args.model.split("/")[-1]}.tsv'
    df.to_csv(CSV_OUTPUTS_DIR / out_filename, sep='\t')


if __name__ == '__main__':
    main()
