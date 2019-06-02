<div class="docs-nav">
  {% if page.prev_link %}
  <p class="docs-nav-item">
    <a href="{{page.prev_link}}">&lt;- {{ page.prev_name }}</a>
  </p>
  {% endif %}
  {% if page.top_link %}
  <p class="docs-nav-item">
    <a href="{{ page.top_link }}">{{ page.top_name }}</a>
  </p>
  {% endif %}
  {% if page.next_link %}
  <p class="docs-nav-item">
    <a href="{{ page.next_link }}">{{ page.next_name }} -&gt;</a>
  </p>
  {% endif %}
</div>  