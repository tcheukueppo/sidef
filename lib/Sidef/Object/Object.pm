package Sidef::Object::Object {

    use 5.014;
    require Scalar::Util;

    use overload
      q{~~}   => \&{__PACKAGE__ . '::' . '~~'},
      q{bool} => sub {
        if (defined(my $sub = $_[0]->can('to_b'))) {
            $sub->($_[0]);
        }
        else {
            $_[0];
        }
      },
      q{0+} => sub {
        if (defined(my $sub = $_[0]->can('to_n'))) {
            $sub->($_[0]);
        }
        else {
            $_[0];
        }
      },
      q{""} => sub {
        if (defined(my $sub = $_[0]->can('to_s'))) {
            $sub->($_[0]);
        }
        else {
            $_[0];
        }
      },
      q{cmp} => sub {
        my ($obj1, $obj2, $first) = @_;

        if (CORE::ref($obj1) && $obj1->SUPER::isa(CORE::ref($obj2)) or CORE::ref($obj2) && $obj2->SUPER::isa(CORE::ref($obj1)))
        {
            if (defined(my $sub = $obj1->can('<=>'))) {
                my $result = $sub->($obj1, $obj2);
                local $Sidef::Types::Number::Number::GET_PERL_VALUE = 1;
                return $result->get_value;
            }
        }

        Scalar::Util::refaddr($obj1) <=> (CORE::ref($obj2) ? Scalar::Util::refaddr($obj2) : $first ? -1 : 'inf');
      },
      q{eq} => sub {
        my ($obj1, $obj2) = @_;

        ($obj1->SUPER::isa(CORE::ref($obj2) || return) || $obj2->SUPER::isa(CORE::ref($obj1) || return))
          || return;

        if (defined(my $sub = $obj1->can('=='))) {
            return ${$sub->($obj1, $obj2)};
        }

        Scalar::Util::refaddr($obj1) == Scalar::Util::refaddr($obj2);
      };

    sub new {
        bless {}, __PACKAGE__;
    }

    sub say {
        Sidef::Types::Bool::Bool->new(CORE::say @_);
    }

    *println = \&say;

    sub print {
        Sidef::Types::Bool::Bool->new(CORE::print @_);
    }

    sub method {
        my ($self, $method, @args) = @_;
        Sidef::Variable::LazyMethod->new(obj => $self, method => $method, args => \@args);
    }

    #~ sub lazy {
    #~ my ($self) = @_;
    #~ Sidef::Lazy::Lazy->new($self);
    #~ }

    sub object_id {
        my ($self) = @_;
        Sidef::Types::Number::Number->new(Scalar::Util::refaddr($self));
    }

    sub class {
        my ($obj) = @_;
        my $ref = CORE::ref($obj) || $obj;

        my $rindex = rindex($ref, '::');
        Sidef::Types::String::String->new($rindex == -1 ? $ref : substr($ref, $rindex + 2));
    }

    sub ref {
        my ($obj) = @_;
        Sidef::Types::String::String->new(CORE::ref($obj) || $obj);
    }

    sub bless {
        my ($obj, $arg) = @_;
        bless($arg, (CORE::ref($obj) || $obj));
    }

    sub respond_to {
        my ($self, $method) = @_;
        Sidef::Types::Bool::Bool->new($self->can($method));
    }

    sub is_a {
        my ($self, $obj) = @_;
        Sidef::Types::Bool::Bool->new($self->SUPER::isa(CORE::ref($obj) || $obj));
    }

    *is_an = \&is_a;

    sub parent_classes {
        my ($obj) = @_;

        no strict 'refs';

        my %seen;
        my $extract_parents;
        $extract_parents = sub {
            my ($ref) = @_;

            my @parents = @{${$ref . '::'}{ISA}};

            if (@parents) {
                foreach my $parent (@parents) {
                    next if $seen{$parent}++;
                    push @parents, $extract_parents->($parent);
                }
            }

            @parents;
        };

        Sidef::Types::Array::Array->new(map { Sidef::Types::String::String->new($_) } $extract_parents->(CORE::ref($obj)));
    }

    sub super_join {
        my ($self, @args) = @_;
        $self->new(
            CORE::join(
                '',
                map {
                    eval { ${CORE::ref($_) ne 'Sidef::Types::String::String' ? $_->to_s : $_} }
                      // $_
                  } @args
            )
        );
    }

    {
        no strict 'refs';

        sub def_method {
            my ($self, $name, $block) = @_;
            *{(CORE::ref($self) ? CORE::ref($self) : $self) . '::' . $name} = sub {
                $block->call(@_);
            };
            $self;
        }

        sub undef_method {
            my ($self, $name) = @_;
            delete ${(CORE::ref($self) ? CORE::ref($self) : $self) . '::'}{$name};
            $self;
        }

        sub alias_method {
            my ($self, $old, $new) = @_;

            my $ref = (CORE::ref($self) ? CORE::ref($self) : $self);
            my $to = \&{$ref . '::' . $old};

            if (not defined &$to) {
                die "[ERROR] Can't alias the nonexistent method '$old' as '$new'!";
            }

            *{$ref . '::' . $new} = $to;
        }

        sub methods {
            my ($self) = @_;

            my %alias;
            my %methods;
            my $ref = CORE::ref($self);
            foreach my $method (grep { $_ !~ /^[(_]/ and defined(&{$ref . '::' . $_}) } keys %{$ref . '::'}) {
                $methods{$method} = (
                                     $alias{\&{$ref . '::' . $method}} //=
                                       Sidef::Variable::LazyMethod->new(
                                                                        obj    => $self,
                                                                        method => \&{$ref . '::' . $method}
                                                                       )
                                    );
            }

            Sidef::Types::Hash::Hash->new(%methods);
        }

        # Logical AND
        *{__PACKAGE__ . '::' . '&&'} = sub {
            $_[0] ? $_[1] : $_[0];
        };

        # Logical OR
        *{__PACKAGE__ . '::' . '||'} = sub {
            $_[0] ? $_[0] : $_[1];
        };

        # Logical XOR
        *{__PACKAGE__ . '::' . '^'} = sub {
            Sidef::Types::Bool::Bool->new($_[0] xor $_[1]);
        };

        # Defined-OR
        *{__PACKAGE__ . '::' . '\\\\'} = sub {
            defined($_[0]) ? $_[1] : $_[0];
        };

        # Smart match operator
        *{__PACKAGE__ . '::' . '~~'} = sub {
            my ($first, $second) = @_;

            my $f_type = CORE::ref($first);
            my $s_type = CORE::ref($second);

            # First is String
            if (   $f_type eq 'Sidef::Types::String::String'
                or $f_type eq 'Sidef::Types::Glob::File'
                or $f_type eq 'Sidef::Types::Glob::Dir') {

                # String ~~ Array
                if ($s_type eq 'Sidef::Types::Array::Array') {
                    return $second->contains($first);
                }

                # String ~~ RangeString
                if ($s_type eq 'Sidef::Types::Range::RangeString') {
                    return $second->contains($first);
                }

                # String ~~ Hash
                if ($s_type eq 'Sidef::Types::Hash::Hash') {
                    return $second->exists($first);
                }

                # String ~~ String
                if ($s_type eq 'Sidef::Types::String::String') {
                    return $second->eq($first);
                }

                # String ~~ Regex
                if ($s_type eq 'Sidef::Types::Regex::Regex') {
                    return $second->match($first)->is_successful;
                }
            }

            # First is Number
            if ($f_type eq 'Sidef::Types::Number::Number') {

                # Number ~~ RangeNumber
                if ($s_type eq 'Sidef::Types::Range::RangeNumber') {
                    return $second->contains($first);
                }

                # Number ~~ Array
                if ($s_type eq 'Sidef::Types::Array::Array') {
                    return $second->contains($first);
                }
            }

            # First is RangeNumber
            if ($f_type eq 'Sidef::Types::Range::RangeNumber') {

                # RangeNumber ~~ Number
                if ($s_type eq 'Sidef::Types::Number::Number') {
                    return $first->contains($second);
                }
            }

            # First is RangeString
            if ($f_type eq 'Sidef::Types::Range::RangeString') {

                # RangeString ~~ String
                if ($s_type eq 'Sidef::Types::String::String') {
                    return $first->contains($second);
                }
            }

            # First is Array
            if ($f_type eq 'Sidef::Types::Array::Array') {

                # Array ~~ Array
                if ($s_type eq 'Sidef::Types::Array::Array') {
                    return $second->eq($first);
                }

                # Array ~~ Regex
                if ($s_type eq 'Sidef::Types::Regex::Regex') {
                    return $second->match($first)->is_successful;
                }

                # Array ~~ Hash
                if ($s_type eq 'Sidef::Types::Hash::Hash') {
                    return $first->contains_all($second->keys);
                }

                # Array ~~ Any
                return $first->contains($second);
            }

            # First is Hash
            if ($f_type eq 'Sidef::Types::Hash::Hash') {

                # Hash ~~ Array
                if ($s_type eq 'Sidef::Types::Array::Array') {
                    return $first->keys->contains_all($second);
                }

                # Hash ~~ Hash
                if ($s_type eq 'Sidef::Types::Hash::Hash') {
                    return $second->eq($first->keys);
                }

                # Hash ~~ Regex
                if ($s_type eq 'Sidef::Types::Regex::Regex') {
                    return $second->match($first->keys)->is_successful;
                }

                # Hash ~~ Any
                return $first->exists($second);
            }

            # First is Regex
            if ($f_type eq 'Sidef::Types::Regex::Regex') {

                # Regex ~~ Array
                if ($s_type eq 'Sidef::Types::Array::Array') {
                    return $first->match($second)->is_successful;
                }

                # Regex ~~ Hash
                if ($s_type eq 'Sidef::Types::Hash::Hash') {
                    return $first->match($second->keys)->is_successful;
                }

                # Regex ~~ Any
                return $first->match($second)->is_successful;
            }

            # Second is Array
            if ($s_type eq 'Sidef::Types::Array::Array') {

                if ($f_type eq 'Sidef::Types::Array::Array') {
                    return $first->eq($second);
                }

                # Any ~~ Array
                return $second->contains($first);
            }

            Sidef::Types::Bool::Bool->new($first eq $second);
        };

        # Negation of smart match
        *{__PACKAGE__ . '::' . '!~'} = sub {
            state $method = '~~';
            $_[0]->$method($_[1])->not;
        };
    }
}

1;
