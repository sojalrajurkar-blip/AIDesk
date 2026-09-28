import os
from dotenv import load_dotenv
import psycopg2

load_dotenv()
user = os.getenv('POSTGRES_USER', 'postgres')
pwd = os.getenv('POSTGRES_PASSWORD', '')
host = os.getenv('POSTGRES_SERVER', 'localhost')
port = os.getenv('POSTGRES_PORT', '5432')
target_db = os.getenv('POSTGRES_DB', 'ai_helpdesk')

try:
    conn = psycopg2.connect(host=host, port=port, user=user, password=pwd, dbname='postgres', connect_timeout=5)
    conn.autocommit = True
    cur = conn.cursor()
    print('Connected to PostgreSQL server successfully!')
    cur.execute('SELECT 1 FROM pg_database WHERE datname = %s;', (target_db,))
    if not cur.fetchone():
        cur.execute(f'CREATE DATABASE "{target_db}";')
        print(f'Database "{target_db}" created!')
    else:
        print(f'Database "{target_db}" already exists.')
    conn.close()
    
    # Test connection to target db
    conn2 = psycopg2.connect(host=host, port=port, user=user, password=pwd, dbname=target_db, connect_timeout=5)
    print(f'Connected to target database "{target_db}" successfully!')
    conn2.close()
except Exception as e:
    print(f'Database connection error: {e}')
