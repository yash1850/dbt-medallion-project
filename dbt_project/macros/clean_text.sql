-- removes extra spaces and fixes capital letters
{% macro clean_text(column_name) %}
    initcap(trim({{ column_name }}))
{% endmacro %}
