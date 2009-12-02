use strict;
use warnings;
use lib 't/lib';
use TestFilter;

add_callbacks(
  remove_script => {
    script => {
      start => sub { shift->remove_text_and_tag },
      end   => sub { shift->remove_text_and_tag },
    },
  },
  remove_on_attr => {
    '*' => {
      start => sub { shift->remove_attr(qr/^on_/) },
    },
  },
  replace_src => {
    img => {
      start => sub { shift->replace_attr(src => sub { s/foo/bar/; $_ }) },
    },
  },
  replace_blank_attr => {
    p => {
      start => sub { shift->replace_attr(id => "pid") },
    },
  },
  add_submit => {
    form => {
      start => sub {
        my ($tag, $c) = @_;
        $c->stash->{__form_has_submit} = 0;
      },
      end   => sub {
        my ($tag, $c) = @_;
        $tag->prepend(qq/<input type="submit">\n/)
          unless $c->stash->{__form_has_submit};
        delete $c->stash->{__form_has_submit};
      },
    },
    input => {
      start => sub {
        my ($tag, $c) = @_;
        $c->stash->{__form_has_submit} = 1
          if $tag->attr('type') eq 'submit';
      },
    }
  },
);

test_all;

__END__
=== remove script tags
--- remove_script
<html>
<head>
<script>
<!-- javascript
//-->
</script>
</head>
</html>
---
<html>
<head>
</head>
</html>
=== remove on_ attributes
--- remove_on_attr
<a href="foo" on_click="bar">
---
<a href="foo">
=== replace attribute
--- replace_src
<img src="foo" name="foo">
---
<img src="bar" name="foo">
=== add a submit button
--- add_submit
<form>
</form>
---
<form>
<input type="submit">
</form>
=== don't need to add the submit button
--- add_submit
<form>
<input type="submit">
</form>
---
<form>
<input type="submit">
</form>
=== replace blank attr
--- replace_blank_attr
<p id="">
---
<p id="pid">
