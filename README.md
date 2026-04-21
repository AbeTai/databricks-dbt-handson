# databricks-dbt-handson

Databricks の `samples.tpch` を使い、Bronze / Silver / Gold の3層で TPC-H 注文データを変換する dbt ハンズオン用リポジトリです。参加者が GitHub からクローンして、dbt Cloud または dbt CLI から実行できる構成にしています。

具体的な作業手順は [HANDSON_STEPS.md](HANDSON_STEPS.md) を参照してください。

## 事前準備

- Databricks ワークスペース
- Databricks SQL Warehouse
- Databricks の Personal Access Token
- dbt Cloud アカウント、または `dbt-databricks` を利用できるローカル dbt 環境
- GitHub アカウント

## セットアップ手順

1. このリポジトリをクローンします。
2. `profiles.yml` を編集し、Databricks 接続情報を自分の環境に合わせて設定します。

```yaml
databricks_dbt_handson:
  target: dev
  outputs:
    dev:
      type: databricks
      host: <your-workspace-host>
      http_path: <your-sql-warehouse-path>
      token: <your-personal-access-token>
      catalog: main
      schema: dev
      threads: 4
```

`host` には `adb-xxxx.azuredatabricks.net` のようなワークスペースホスト、`http_path` には SQL Warehouse の HTTP Path、`token` には Personal Access Token を設定してください。

dbt Cloud を使う場合は、Cloud 側の接続設定に同じ Databricks 接続情報を登録します。リポジトリ内の `profiles.yml` はローカル実行用テンプレートです。

## 実行コマンド

```bash
dbt deps
dbt run
dbt test
```

ローカルで `profiles.yml` をリポジトリ直下から利用する場合は、次のように `--profiles-dir` を指定します。

```bash
dbt deps --profiles-dir .
dbt run --profiles-dir .
dbt test --profiles-dir .
```

## ディレクトリ構成

```text
.
├── dbt_project.yml
├── HANDSON_STEPS.md
├── profiles.yml
├── packages.yml
├── macros/
│   └── generate_schema_name.sql
├── models/
│   ├── bronze/
│   │   ├── sources.yml
│   │   ├── bronze_orders.sql
│   │   └── bronze_lineitem.sql
│   ├── silver/
│   │   ├── schema.yml
│   │   ├── silver_orders.sql
│   │   └── silver_lineitem.sql
│   └── gold/
│       ├── schema.yml
│       ├── gold_monthly_revenue.sql
│       └── gold_order_status_summary.sql
└── README.md
```

`models/bronze` は Databricks の `samples.tpch` をそのまま参照する View、`models/silver` は分析しやすいカラム名と計算値を持つ Table、`models/gold` はダッシュボード向けの集計 Table です。`macros/generate_schema_name.sql` は、dbt のカスタムスキーマ名を `bronze` / `silver` / `gold` としてそのまま利用するためのマクロです。

## メダリオンアーキテクチャ

メダリオンアーキテクチャは、データを Bronze、Silver、Gold の段階に分けて整備する設計です。Bronze ではソースデータをほぼそのまま保持し、Silver では型やカラム名を整えて分析しやすくし、Gold では BI やダッシュボードで使いやすい集計済みデータを作成します。

このリポジトリでは、Databricks Unity Catalog の `main` カタログ配下に `bronze`、`silver`、`gold` の各スキーマを作成してモデルを出力します。
