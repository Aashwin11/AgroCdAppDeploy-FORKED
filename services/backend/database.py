from sqlalchemy.orm import sessionmaker
from sqlalchemy import create_engine

db_url="postgresql://postgres:76b40645e6dd4236b5dfa99676d24246@localhost:5432/Fastapi_db_table"
engine=create_engine(db_url)
session=sessionmaker(autocommit=False,autoflush=False,bind=engine)