# SHAKE-TEI-ből

import csv
import argparse
from pathlib import Path

from bs4 import BeautifulSoup

from nltk.tokenize.punkt import PunktSentenceTokenizer

DIR_PATH = Path(__file__).resolve().parent

# create output folder if it doesn't exist
CSV_OUTPUTS_DIR = DIR_PATH / 'tsv_outputs'
if not CSV_OUTPUTS_DIR.is_dir():
    CSV_OUTPUTS_DIR.mkdir(parents=True, exist_ok=True)


def create_line_text(line, char_names=()):
    line_text_list = []
    for c, token_tag in enumerate(line.find_all()):
        parent_token = token_tag.find_parent()
        if token_tag.name != 'stage' and parent_token.name != 'stage':

            if token_tag.name == 'lb' and c > 0:
                line_text_list.append(' ')
            else:
                if token_tag.name == 'w':
                    try:
                        if token_tag['lemma'] not in char_names:
                            line_text_list.append(token_tag.get_text())
                    except KeyError:
                        print(parent_token.name)

                else:
                    line_text_list.append(token_tag.get_text())
    return ''.join(line_text_list)  # line text


def speech_generator_with_name_replace(soup, remove_char_names=False):
    # For shakespear TEI dramas
    if remove_char_names:
        char_names = [p.get_text(strip=True) for p in soup.find('listPerson').find_all('persName')]
    else:
        char_names = ()

    for act in soup.find_all('div', {'type': 'act'}):
        act_number = act['n']
        for sp in act.find_all('sp', {'who': True}):
            speaker_name = sp['who']

            lines = []

            line_struc = sp.find('l', recursive=False)
            if line_struc is not None:
                for line in sp.find_all('l', recursive=False):

                    q_tags = line.find_all('q', recursive=False)
                    if len(q_tags) > 0:
                        for q_tag in q_tags:
                            lines.append(create_line_text(q_tag, char_names))
                    else:
                        lines.append(create_line_text(line, char_names))

            p_struc = sp.find('p', recursive=False)
            if p_struc is not None:
                for p_tag in sp.find_all('p', recursive=False):

                    q_tags = p_tag.find_all('q', recursive=False)
                    if len(q_tags) > 0:
                        for q_tag in q_tags:
                            lines.append(create_line_text(q_tag, char_names))
                    else:
                        lines.append(create_line_text(p_tag, char_names))
            q_struc = sp.find('q', recursive=False)
            if q_struc:
                for q_tag in sp.find_all('q', recursive=False):
                    lg_tags = q_tag.find_all('lg', recursive=False)
                    if len(lg_tags) > 0:
                        for lg_tag in lg_tags:
                            for line in lg_tag.find_all('l', recursive=False):
                                lines.append(create_line_text(line, char_names))
                    else:
                        lines.append(create_line_text(q_tag, char_names))

            lg_tags = sp.find_all('lg', recursive=False)
            if len(lg_tags) > 0:
                for lg_tag in lg_tags:
                    for line in lg_tag.find_all('l', recursive=False):
                        lines.append(create_line_text(line, char_names))

            yield speaker_name, ' '.join(lines), act_number


def speaker_speech_actnum_iter_gen(file_path, remove_char_names):
    with open(file_path, encoding='utf-8') as fh:
        drama_soup = BeautifulSoup(fh.read(), 'lxml-xml')

    speaker_speech_pairs = []
    for speaker, speech, act_num in speech_generator_with_name_replace(drama_soup, remove_char_names=remove_char_names):
        speech = speech.replace('—', ' — ')
        speaker_speech_pairs.append((speaker, speech, act_num))

    all_speech = ' '.join([speech for _, speech, _ in speaker_speech_pairs])

    tokenizer = PunktSentenceTokenizer()
    tokenizer.train(all_speech)

    for speaker, speech, act_num in speaker_speech_pairs:
        sents = tokenizer.tokenize(speech)
        for sent in sents:
            yield speaker, sent, act_num


def write_tsv(file_path, csv_outputs_dir, speaker_speech_actnum_iter):
    if isinstance(file_path, Path):
        out_tsv_filename = f'{file_path.stem}.tsv'
    else:  # in str format
        out_tsv_filename = str(file_path).split('/')[-1].split('\\')[-1].replace('.xml', '.tsv')

    timestamp_start = 946684800000  # 2000-01-01:00:00:00:00

    with open(csv_outputs_dir / out_tsv_filename, 'w', encoding='utf-8', newline='') as fh:
        drama_writer = csv.writer(fh, delimiter='\t')
        drama_writer.writerow(['speech', 'created_at', 'character', 'act_number'])
        for timestamp, (speaker, speech, act_num) in enumerate(speaker_speech_actnum_iter,
                                                               start=timestamp_start):
            if len(speech.strip()) > 0:  # This excludes empty speeches, e.g.: <gap> tag.
                drama_writer.writerow([speech, timestamp, speaker, act_num])
        print(f'Created {out_tsv_filename} !')


def main():
    parser = argparse.ArgumentParser()
    parser.add_argument('filepath', help="Filename, make sure file is in same directory")
    parser.add_argument('-r', '--remove_char_names', action='store_true', default=False,
                        help='Character names are removed from strings')
    args = parser.parse_args()

    drama_path = Path(args.filepath)

    # if file not found in directory, and directory not found in BASE_DIR try creating absolute path
    if drama_path.is_dir() is False and drama_path.is_file() is False:
        drama_path = DIR_PATH / args.filepath

    # if drama_path is a directory, process all files within it
    if drama_path.is_dir():
        to_process = [xml_path for xml_path in drama_path.glob('*.xml')]
    # If drama_path is a file, process as single file
    elif drama_path.is_file():
        to_process = [drama_path]
    else:
        raise NotImplementedError(f'The following path could not be processed: {args.filepath}')

    for file_path in to_process:
        speaker_speech_actnum_iter = speaker_speech_actnum_iter_gen(file_path, remove_char_names=args.remove_char_names)
        write_tsv(file_path, CSV_OUTPUTS_DIR, speaker_speech_actnum_iter)


if __name__ == '__main__':
    main()
