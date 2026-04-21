{% macro workspace_ref(model_name) -%}
  {%- set relation = ref(model_name) -%}
  workspace.{{ relation.schema }}.{{ relation.identifier }}
{%- endmacro %}
