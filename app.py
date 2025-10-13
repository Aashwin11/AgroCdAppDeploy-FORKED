import requests
from flask import Flask, request, render_template
import os

app = Flask(__name__)


APIKEY = os.getenv("APIKEY")
APIHOST = os.getenv("APIHOST")

url = "https://currency-conversion-and-exchange-rates.p.rapidapi.com/convert"
headers = {
    "X-RapidAPI-Key": APIKEY,
    "X-RapidAPI-Host": APIHOST,
}


@app.route("/")
def index():
    return render_template("index.html")


@app.route("/convert", methods=["GET"])
def get_currency_value():
    source_currency = request.args.get("from", default="USD", type=str).upper()
    target_currency = request.args.get("to", default="USD", type=str).upper()
    amount = request.args.get("amount", default=1, type=float)
    querystring = {"from": source_currency, "to": target_currency, "amount": amount}
    response = requests.get(url, headers=headers, params=querystring)
    return response.json()


if __name__ == "__main__":
    env = os.getenv("FLASK_ENV", "development")
    debug_mode = env == "development"
    app.run(debug=debug_mode, host="0.0.0.0", port=5555)