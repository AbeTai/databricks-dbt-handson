{{ config(database='workspace') }}

-- Bronze レイヤーはソースデータを加工せず、そのまま後続レイヤーへ受け渡す役割を持ちます。

select *
from {{ source('tpch', 'lineitem') }}
