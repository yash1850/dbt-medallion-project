-- line total = quantity * price
{% macro line_total(quantity, price) %}
    {{ quantity }} * {{ price }}
{% endmacro %}
