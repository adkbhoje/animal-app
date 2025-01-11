from flask import Flask, render_template

app = Flask(__name__)

animals = [
    {"name": "Lion", "details": "King of the jungle"},
    {"name": "Elephant", "details": "Largest land animal"},
    {"name": "Tiger", "details": "Powerful and fast predator"}
]

@app.route("/")
def home():
    return render_template('index.html', animals=animals)

@app.route("/<animal>")
def animal_detail(animal):
    details = next(item for item in animals if item["name"].lower() == animal.lower())
    return render_template('animal_detail.html', details=details)

if __name__ == "__main__":
    app.run(debug=True, host='0.0.0.0')