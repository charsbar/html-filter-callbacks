package HTML::Filter::Callbacks;

use strict;
use warnings;
use base 'HTML::Parser';
use HTML::Filter::Callbacks::Tag;

our $VERSION = '0.01';

my %Handlers = (
  start => [\&_handler, 'self,event,tokens,text,skipped_text'],
  end   => [\&_handler, 'self,event,tokens,text,skipped_text'],
  end_document => [sub { $_[0]->_add_chunk($_[1]) }, 'self,skipped_text'],
);

sub init {
  my ($self, %args) = @_;
  $self->_alloc_pstate;

  foreach my $event (keys %Handlers) {
    $self->handler($event => @{$Handlers{$event}});
  }
  $self->{__tag} = HTML::Filter::Callbacks::Tag->new(%args);

  $self;
}

sub process {
  my ($self, $html) = @_;

  $self->{__res} = [];

  $self->parse($html);
  $self->eof;

  return join '', @{ $self->{__res} };
}

sub add_callbacks {
  my ($self, @callbacks) = @_;

  while (my ($tag, $handlers) = splice @callbacks, 0, 2) {
    foreach my $event (keys %$handlers) {
      my $cb = $handlers->{$event};
      push @{ $self->{__cb}{$tag}{$event} ||= [] }, $cb unless $self->{__seen}{$cb}++;
    }
  }
}

sub stash { shift->{__stash} ||= {} }

sub _add_chunk { push @{ $_[0]->{__res} }, $_[1] if defined $_[1] }

sub _handler {
  my ($self, $event, $tokens, $org, $skipped_text) = @_;
  $self->{__tag}->set($tokens, $org, $skipped_text);
  $self->_run($self->{__cb}{$self->{__tag}->name}{$event});
  if ($self->{__cb}{'*'}) {
    $self->_run($self->{__cb}{'*'}{$event});
  }
  $self->_add_chunk($self->{__tag}->as_string);
}

sub _run {
  my ($self, $callbacks) = @_;

  return unless $callbacks;
  foreach my $cb (@$callbacks) {
    $cb->($self->{__tag}, $self);
  }
}

1;

__END__

=head1 NAME

HTML::Filter::Callbacks - modify HTML with callbacks

=head1 SYNOPSIS

  use HTML::Filter::Callbacks;

  # Case 1: remove script tags
  my $filter = HTML::Filter::Callbacks->new;
  $filter->add_callbacks(
    script => {
      start => sub { shift->remove_text_and_tag },
      end   => sub { shift->remove_text_and_tag },
    },
  );
  my $new_html = $filter->process($html);

  # Case 2: remove on_* attributes
  my $filter = HTML::Filter::Callbacks->new;
  $filter->add_callbacks(
    '*' => {
      start => sub { shift->remove_attr(qr/^on_/) },
    },
  );
  my $new_html = $filter->process($html);

  # Case 3: replace url of <img src="...">
  my $filter = HTML::Filter::Callbacks->new;
  $filter->add_callbacks(
    'img' => {
      start => sub {
        shift->replace_attr(src => sub { URI->new(shift)->canonical })
      },
    },
  );
  my $new_html = $filter->process($html);

  # Case 4: more complex example to enforce a submit button
  my $filter = HTML::Filter::Callbacks->new;
  $filter->add_callbacks(
    'form' => {
      start => sub {
        my ($tag, $c) = @_;
        $c->stash->{__form_has_submit} = 0;
      },
      end => sub {
        my ($tag, $c) = @_;
        $tag->prepend(qq/<input type="submit">\n/)
          unless $c->stash->{__form_has_submit};
        delete $c->stash->{__form_has_submit};
      }
    },
    'input' => {
      start => sub {
        my ($tag, $c) = @_;
        $c->stash->{__form_has_submit} = 1
          if $tag->attr('type') eq 'submit';
      }
    },
  );
  my $new_html = $filter->process($html);

=head1 DESCRIPTION

This is a rather simple HTML filter, based on L<HTML::Parser>. 

=head1 METHODS

=head2 new

creates an object.

=head2 process

=head2 add_callbacks

=head2 stash

=head2 init

used internally.

=head1 SEE ALSO

L<HTML::Parser>

=head1 AUTHOR

Kenichi Ishigaki, E<lt>ishigaki@cpan.orgE<gt>

=head1 COPYRIGHT AND LICENSE

Copyright (C) 2009 by Kenichi Ishigaki.

This program is free software; you can redistribute it and/or
modify it under the same terms as Perl itself.

=cut
