from flask import Flask

app = Flask(__name__)

@app.route("/")
def hello():
    return "hello world"

@app.route("/age/<name>")
def age(name):
    data = {
        "毛银露": 18,
        "张三": 20
    }

    return {
        "name": name,
        "age": data.get(name, "未知")
    }

app.run(host="0.0.0.0", port=5000)