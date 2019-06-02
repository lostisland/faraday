<div class="docs-nav">
  <p class="docs-nav-item">
  {% if page.prev_link %}
    <a href="{{page.prev_link}}">&lt;- {{ page.prev_name }}</a>
  {% endif %}
  </p>
  <p class="docs-nav-item">
  {% if page.top_link %}
    <a href="{{ page.top_link }}">{{ page.top_name }}</a>
  {% endif %}
  </p>
  <p class="docs-nav-item">
  {% if page.next_link %}
    <a href="{{ page.next_link }}">{{ page.next_name }} -&gt;</a>
  {% endif %}
  </p>
</div>  