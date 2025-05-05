import random
from flask import Flask, request, jsonify

app = Flask(__name__)

def mock_lstm_predict(purchase_history):
    common_items = [
        "milk", "bread", "eggs", "cheese", "butter",
        "cereal", "juice", "apples", "bananas", "chicken"
    ]
    
    predictions = [item for item in common_items if item not in purchase_history]
    return random.sample(predictions, min(3, len(predictions)))

@app.route('/predict', methods=['POST'])
def predict():
    data = request.json
    history = data.get("history", [])
    predictions = mock_lstm_predict(history)
    return jsonify({"predictions": predictions})

if __name__ == '__main__':
    app.run(debug=True, port=5000)
