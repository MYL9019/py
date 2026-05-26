from flask import Flask, jsonify

app = Flask(__name__)

# 关闭中文 Unicode 转义
app.json.ensure_ascii = False

@app.route("/")
def hello():
    return "hello world"

@app.route("/age/<name>")
def age(name):
    data = {
        "毛银露": {
            "name": "毛银露",
            "age": 18
        },
        "zhangsan": {
            "name": "张三",
            "age": 20
        }
    }

    return jsonify(
        data.get(name, {
            "name": name,
            "age": "未知"
        })
    )

if __name__ == "__main__":
    app.run(host="0.0.0.0", port=5000)