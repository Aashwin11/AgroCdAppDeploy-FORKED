from sqlalchemy.orm import sessionmaker
from sqlalchemy import create_engine
import os


default_db_url = "postgresql://postgres:postgres@localhost:5432/Fastapi_db_table"

db_url = os.getenv("DATABASE_URL", default_db_url)
engine=create_engine(db_url)
session=sessionmaker(autocommit=False,autoflush=False,bind=engine)