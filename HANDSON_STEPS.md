# ハンズオン作業手順

このドキュメントは、参加者が `databricks-dbt-handson` を使って dbt と Databricks の基本的なデータ変換を体験するための手順書です。dbt Cloud での実行を主な想定とし、ローカル dbt CLI で実行する場合の補足も記載します。

## 1. 作業の全体像

このハンズオンでは、Databricks のサンプルデータ `samples.tpch` を使って、次の流れでデータモデルを作成します。

1. Bronze: ソーステーブルを加工せずに参照する View を作成する
2. Silver: カラム名の整理、型変換、計算カラム追加を行う Table を作成する
3. Gold: ダッシュボードで使いやすい集計 Table を作成する
4. dbt test: Silver モデルに定義したデータテストを実行する

作成される主なモデルは次の通りです。

| レイヤー | モデル | 内容 |
|---|---|---|
| Bronze | `bronze_orders` | `samples.tpch.orders` をそのまま参照 |
| Bronze | `bronze_lineitem` | `samples.tpch.lineitem` をそのまま参照 |
| Silver | `silver_orders` | 注文データのカラム名とステータス表示を整理 |
| Silver | `silver_lineitem` | 注文明細データのカラム名を整理し、売上金額を追加 |
| Gold | `gold_monthly_revenue` | 月別、注文ステータス別の売上集計 |
| Gold | `gold_order_status_summary` | 注文ステータス別の件数、金額、構成比 |

## 2. 事前準備

作業前に次のアカウントと権限を用意してください。

- GitHub アカウント
- dbt Cloud アカウント
- Databricks ワークスペース
- Databricks SQL Warehouse を利用できる権限
- Unity Catalog の `workspace` カタログに `bronze`、`silver`、`gold` スキーマを作成または利用できる権限
- Databricks Personal Access Token を発行できる権限

Databricks で `samples.tpch.orders` と `samples.tpch.lineitem` が参照できることも確認してください。

## 3. GitHub リポジトリを準備する

講師が用意した GitHub リポジトリを使う場合は、この手順でクローンします。

```bash
git clone <repository-url>
cd databricks-dbt-handson
```

自分の GitHub アカウントにコピーして使う場合は、GitHub の Fork 機能を使うか、新しいリポジトリを作成して push します。

```bash
git remote add origin <your-repository-url>
git push -u origin main
```

## 4. Databricks SQL Warehouse を確認する

Databricks ワークスペースで次の情報を確認します。

1. Databricks にログインします。
2. サイドバーから SQL Warehouse の画面を開きます。
3. 利用する SQL Warehouse が起動していることを確認します。
4. SQL Warehouse の接続情報から `HTTP Path` を控えます。
5. ブラウザの URL や接続情報からワークスペースホスト名を控えます。

ワークスペースホスト名は、通常 `adb-xxxx.azuredatabricks.net` のような形式です。`https://` は dbt Cloud 側の入力欄に合わせて必要有無を判断してください。

## 5. Databricks Token を発行する

Databricks で Personal Access Token を発行します。

1. Databricks 画面右上のユーザー設定を開きます。
2. Developer または Access tokens の画面を開きます。
3. Generate new token を選択します。
4. 用途が分かる名前を付けます。
5. 有効期限を設定します。
6. 発行された token を控えます。

token は一度しか表示されないことがあります。公開リポジトリ、チャット、共有ドキュメントには貼り付けないでください。

## 6. dbt Cloud プロジェクトを作成する

dbt Cloud で新しいプロジェクトを作成します。

1. dbt Cloud にログインします。
2. New Project を選択します。
3. Project name に `databricks-dbt-handson` を入力します。
4. Data platform として Databricks を選択します。
5. Databricks 接続情報を入力します。

主な接続項目は次の通りです。

| 項目 | 設定値 |
|---|---|
| Host | Databricks ワークスペースホスト |
| HTTP Path | SQL Warehouse の HTTP Path |
| Token | Databricks Personal Access Token |
| Catalog | `workspace` |
| Schema | `dev` |

dbt project name と profile name は `databricks_dbt_handson` です。

Databricks の Unity Catalog を使うため、Catalog は必ず `workspace` を指定してください。Catalog が未指定のままだと、環境によっては `hive_metastore` に作成しようとして `UC_HIVE_METASTORE_DISABLED_EXCEPTION` が発生します。このリポジトリでは `dbt_project.yml` に `+database: workspace` を設定して、モデルの出力先カタログも `workspace` に固定しています。Databricks では dbt の `database` が Unity Catalog の catalog に対応します。

`workspace.bronze`、`workspace.silver`、`workspace.gold` がまだ存在しない場合、dbt 実行時に作成されます。スキーマ作成権限がない場合は、Databricks SQL Editor で事前に次を実行するか、管理者に作成を依頼してください。

```sql
create schema if not exists workspace.bronze;
create schema if not exists workspace.silver;
create schema if not exists workspace.gold;
```

## 7. dbt Cloud と GitHub を接続する

dbt Cloud プロジェクトに GitHub リポジトリを接続します。

1. dbt Cloud のプロジェクト設定を開きます。
2. Repository 設定で GitHub を選択します。
3. `databricks-dbt-handson` リポジトリを選択します。
4. main ブランチを利用する設定にします。
5. dbt Cloud IDE を開き、リポジトリのファイルが表示されることを確認します。

IDE で `dbt_project.yml`、`models/bronze`、`models/silver`、`models/gold` が見えていれば接続は完了です。

## 8. dbt パッケージを取得する

dbt Cloud IDE のコマンド欄で次を実行します。

```bash
dbt deps
```

成功すると、`packages.yml` に定義された `dbt_utils` が取得されます。

## 9. Bronze モデルを確認する

まず Bronze モデルの SQL を確認します。

- `models/bronze/bronze_orders.sql`
- `models/bronze/bronze_lineitem.sql`

Bronze モデルは、ソースデータを加工せずに `select *` で参照します。dbt の `source()` を使っているため、物理テーブル名を SQL に直接書かない構成です。

Bronze モデルだけを実行する場合は次を実行します。

```bash
dbt run --select bronze
```

実行後、Databricks の `workspace.bronze` スキーマに View が作成されます。

## 10. Silver モデルを確認する

次に Silver モデルを確認します。

- `models/silver/silver_orders.sql`
- `models/silver/silver_lineitem.sql`
- `models/silver/schema.yml`

Silver モデルでは、分析しやすい形にカラム名を変換し、不要なカラムを除外します。`silver_lineitem` では `revenue` を計算します。

Silver モデルだけを実行する場合は次を実行します。

```bash
dbt run --select silver
```

実行後、Databricks の `workspace.silver` スキーマに Table が作成されます。

## 11. Gold モデルを確認する

Gold モデルを確認します。

- `models/gold/gold_monthly_revenue.sql`
- `models/gold/gold_order_status_summary.sql`
- `models/gold/schema.yml`

Gold モデルは、BI やダッシュボードで使いやすい集計済みテーブルです。

Gold モデルだけを実行する場合は次を実行します。

```bash
dbt run --select gold
```

実行後、Databricks の `workspace.gold` スキーマに Table が作成されます。

## 12. 全モデルを実行する

依存関係の順序を dbt に任せて、全モデルを実行します。

```bash
dbt run
```

成功すると、Bronze、Silver、Gold の全モデルが作成されます。

期待される作成先は次の通りです。

| レイヤー | 作成先 |
|---|---|
| Bronze | `workspace.bronze` |
| Silver | `workspace.silver` |
| Gold | `workspace.gold` |

## 13. データテストを実行する

Silver モデルに定義されたテストを実行します。

```bash
dbt test
```

主なテスト内容は次の通りです。

| モデル | カラム | テスト |
|---|---|---|
| `silver_orders` | `order_id` | `not_null`, `unique` |
| `silver_orders` | `order_status` | `not_null`, `accepted_values` |
| `silver_lineitem` | `order_id` | `not_null` |
| `silver_lineitem` | `revenue` | `not_null` |
| `silver_lineitem` | `ship_date` | `not_null` |

すべて Pass すれば、今回のハンズオンで定義した基本的な品質チェックは完了です。

## 14. Databricks 上で結果を確認する

Databricks SQL Editor で次のクエリを実行し、作成されたテーブルを確認します。

```sql
select *
from workspace.gold.gold_monthly_revenue
order by order_month, order_status_label
limit 20;
```

```sql
select *
from workspace.gold.gold_order_status_summary
order by order_count desc;
```

Gold テーブルの結果を使うと、月別売上の折れ線グラフや注文ステータス別の棒グラフを作成できます。

## 15. ローカル dbt CLI で実行する場合

ローカルで実行する場合は、`profiles.yml` のプレースホルダーを自分の Databricks 接続情報に置き換えます。

```yaml
databricks_dbt_handson:
  target: dev
  outputs:
    dev:
      type: databricks
      host: <your-workspace-host>
      http_path: <your-sql-warehouse-path>
      token: <your-personal-access-token>
      catalog: workspace
      schema: dev
      threads: 4
```

その後、次のコマンドを実行します。

```bash
dbt deps --profiles-dir .
dbt run --profiles-dir .
dbt test --profiles-dir .
```

## 16. よくあるエラーと確認ポイント

| エラー内容 | 確認ポイント |
|---|---|
| Databricks に接続できない | Host、HTTP Path、Token が正しいか確認する |
| SQL Warehouse が見つからない | SQL Warehouse が起動しているか、HTTP Path が正しいか確認する |
| `samples.tpch` が参照できない | ワークスペースでサンプルデータにアクセスできるか確認する |
| `workspace.bronze` などに作成できない | Unity Catalog のカタログ、スキーマ作成権限を確認する |
| `hive_metastore` に作成しようとして失敗する | dbt Cloud の Databricks 接続設定で Catalog が `workspace` になっているか、`dbt_project.yml` に `+database: workspace` があるか確認する |
| `dbt test` が失敗する | 失敗したモデル、カラム、テスト名を確認し、対象データを SQL で確認する |
| モデルが `dev_bronze` に作成される | `macros/generate_schema_name.sql` が存在するか確認する |

## 17. ハンズオン完了条件

次の状態になれば完了です。

- `dbt deps` が成功している
- `dbt run` が全モデルで成功している
- `dbt test` がすべて Pass している
- Databricks に `workspace.bronze`、`workspace.silver`、`workspace.gold` のオブジェクトが作成されている
- Gold テーブルを SQL Editor で参照できる
