from fastapi import Depends, FastAPI
from fastapi.middleware.cors import CORSMiddleware
#from library_name import class_name
from models import Product
from database import session
import database
import database_models
from sqlalchemy.orm import Session 


app_fastapi=FastAPI()
app_fastapi.add_middleware(
    CORSMiddleware,
    allow_origins=["http://localhost:3000"],
    allow_methods=["*"]
                           )

database_models.Base.metadata.create_all(bind=database.engine)

@app_fastapi.get("/")
def greet():
    return ("Welcome to the Backend:8000")

greet()

products=[
          Product(id=1, name="phone",description="budget phone",price=99,quantity=10),
          Product(id=2, name="Laptop",description="Latop phone",price=1999,quantity=3),
          Product(id=3, name="Pen",description="Budget pen",price=1,quantity=30),
          Product(id=4, name="Table",description="Big Table",price=299,quantity=2),

]

def get_db():
    db=session()
    try:
        yield db
    finally:
        db.close()

def init_db():
    db=session()
    count=db.query(database_models.Product).count
    if count==0:
        for product in products:
        
            db.add(database_models.Product(**product.model_dump()))    
        db.commit()
    
init_db()

#Get all products
@app_fastapi.get("/products")
def get_all_products(db: Session =Depends(get_db)):
    #DB_connection - talks to sqlalchemy. All these configs are done in seperate file
    
    db_products=db.query(database_models.Product).all()
    #write the query
    
    return db_products

#Get product by ID
@app_fastapi.get("/products/{id}")
def get_product_by_id(id:int, db: Session =Depends(get_db)):
    db_product=db.query(database_models.Product).filter(database_models.Product.id== id).first()
    if db_product:
        return db_product
    return "Product not found"
    
    


#Add a record
@app_fastapi.post("/products")
def add_product(product:Product, db: Session =Depends(get_db)):
    db_product=db.add(database_models.Product(**product.model_dump()))
    db.commit()
    return db_product

#Update
@app_fastapi.put("/products/{id}")
def update_product(id:int,product:Product,db: Session =Depends(get_db)):

    #1st try to fetch the data
    db_product=db.query(database_models.Product).filter(database_models.Product.id== id).first()
    if db_product:
        db_product.name=product.name
        db_product.description=product.description
        db_product.price=product.price
        db_product.quantity=product.quantity

        db.commit()    
        return "Product updated"
    else:
        return "No Product found"



#Delete

@app_fastapi.delete("/products/{id}")
def delete_product(id: int, db: Session=Depends(get_db)):
    db_product=db.query(database_models.Product).filter(database_models.Product.id==id).first()
    if db_product:
        db.delete(db_product)
        db.commit()
        return f" Removed from DB"
    else:
        return "Product not found"            




