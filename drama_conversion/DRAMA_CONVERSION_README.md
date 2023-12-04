# DRAMA CONVERSION

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
<br>Write sentence-timestamp-speaker-act_number TSV
<br>`python shake_tei_to_tsv.py path/to/shake-tei.xml`
<br>Write sentence-timestamp-speaker-act_number TSV without character names in sentence
<br>`python shake_tei_to_tsv.py path/to/shake-tei.xml -r`

