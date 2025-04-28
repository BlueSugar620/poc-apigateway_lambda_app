# poc-apigateway_lambda_app

## 概要

API GatewayとLambdaの連携を試しました。
TODOがたくさん残っています。助けてください。

## ディレクトリ構成

```
.
├─ app   
│   └─ lambda                   # Lambdaコード
│       ├─ lambda_function.py
│       ├─ outputs/             # layerを格納する
│       └─ requirements.txt     
└─ terraform
    ├─ apigateway.tf            # API Gatewayの定義
    ├─ data.tf                  # アカウントIDのためのdata
    ├─ lambda                   # lambdaを作成する際のzip
    ├─ lambda.tf                # lambdaの定義
    └─ variables.tf             # 変数定義
```

## Layerの作成方法

以下のコマンドを使用して、layerを作成することができます。

```
$ pwd
app

$ python3 -m venv lambda/outputs/venv
$ lambda/outputs/venv/bin/pip3 install -r lambda/requirements.txt -t lambda/outputs/layer/python --no-cache-dir
```

## 使い方

デプロイする。

```
export TF_VAR_prefix="<プレフィックス名>"

terraform init
terraform apply
```

## TODO

[] - API Gatewayのリソースがそれぞれ何をしているのかよくわかっていません。あとで調べます。
[] - bodyとしてリクエストを受け取ることができていません。LambdaコードをpathStringに書き換えてください。
