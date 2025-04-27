# poc-apigateway_lambda_app

## 概要

API GatewayとLambdaの連携を試しました。後ろのLambdaは、SQSにメッセージを送ります。
TODOがたくさん残っています。助けてください。

## ディレクトリ構成

```
.
├─ app
│   ├─ push-message-to-sqs      # SQSにメッセージを送るためのLambda
│   │   └─ lambda_function.py   
│   └─ read-message-from-sqs    # SQSからメッセージを受け取るためのLambda
│       ├─ lambda_function.py
│       ├─ outputs/             # layerを格納する
│       └─ requirements.txt     
└─ terraform
    ├─ apigateway.tf            # API Gatewayの定義
    ├─ data.tf                  # アカウントIDのためのdata
    ├─ lambda                   # lambdaを作成する際のzip
    ├─ lambda.tf                # lambdaの定義
    ├─ sqs.tf                   # SQSの定義
    └─ variables.tf             # 変数定義
```

## Layerの作成方法

以下のコマンドを使用して、layerを作成することができます。

```
$ pwd
app

$ python3 -m venv read-message-from-sqs/outputs/venv
$ read-message-from-sqs/outputs/venv/bin/pip3 install -r read-message-from-sqs/requirements.txt -t read-message-from-sqs/outputs/layer/python --no-cache-dir
```

## 使い方

デプロイする。

```
export TF_VAR_prefix="<プレフィックス名>"

terraform init
terraform apply
```

## TODO

- [] コールバック部分のテストができていません。`http://localhost`を外部に公開できないからです。
- [] API Gatewayのリソースがそれぞれ何をしているのかよくわかっていません。あとで調べます。
- [] bodyとしてリクエストを受け取ることができていません。LambdaコードをpathStringに書き換えてください。
- [] SQSを間に入れながら、同期処理のような形を目指していることが間違えかもしれません。考える必要があります。
