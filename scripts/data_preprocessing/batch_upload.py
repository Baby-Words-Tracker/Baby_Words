import json
import pandas as pd
import firebase_admin
from firebase_admin import credentials, firestore

# 1. Initialize Firebase Admin SDK
cred = credentials.Certificate("serviceAccountKey.json")
firebase_admin.initialize_app(cred)

db = firestore.client()

# 2. Load your data from the csv file

df = pd.read_csv('byChild_englishAmerican_WG.csv')
df.to_json('byChild_englishAmerican_WG.json', orient='records', indent=4)
with open('byChild_englishAmerican_WG.json', 'r') as f:
    data = json.load(f)


# 3. Reference the collection you want to upload to
collection_ref = db.collection('byChild_EngAmerican_WG') # Naming the collection

# 4. Iterate and upload in batches of 500
batch = db.batch()
count = 0
for record in data:
    # Assuming each record should be its own document
    # You can specify a document ID or let Firestore auto-generate one
    # For example, using the 'data_id' from the record as the document ID
    doc_id = str(record.get('data_id', None)) # Get the data_id for a unique key
    if doc_id:
        doc_ref = collection_ref.document(doc_id)
        batch.set(doc_ref, record)
        count += 1

    # When the batch is full, commit it and start a new one
    if count == 499:
        print('Committing batch of 499 documents...')
        batch.commit()
        batch = db.batch()
        count = 0

if count > 0:
    print(f'Committing final batch of {count} documents...')
    batch.commit()

print('Upload complete!')