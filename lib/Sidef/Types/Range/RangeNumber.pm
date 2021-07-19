package Sidef::Types::Range::RangeNumber {

    use utf8;
    use 5.016;

    use parent qw(
      Sidef::Types::Range::Range
      Sidef::Object::Object
    );

    use overload q{""} => sub {
        my ($self) = @_;
        "RangeNum(" . join(', ', $self->{from}->dump, $self->{to}->dump, $self->{step}->dump) . ")";
    };

    use Sidef::Types::Bool::Bool;
    use Sidef::Types::Number::Number;

    sub new {
        my (undef, $from, $to, $step) = @_;

        if (not defined $from) {
            $from = Sidef::Types::Number::Number::ZERO;
            $to   = Sidef::Types::Number::Number::MONE;
        }

        if (not defined $to) {
            $to   = $from->sub(Sidef::Types::Number::Number::ONE);
            $from = Sidef::Types::Number::Number::ZERO;
        }

        if (ref($to) eq __PACKAGE__) {
            $to = $to->{to};
        }

        bless {
               from => $from,
               to   => $to,
               step => $step // Sidef::Types::Number::Number::ONE,
              },
          __PACKAGE__;
    }

    *call = \&new;

    my @cache;

    sub iter {
        my ($self) = @_;

        my $step = $self->{step};
        my $from = $self->{from};
        my $to   = $self->{to};

        my $times = ($self->{_times} //= $to->sub($from)->add($step)->div($step));

        if (ref($times) eq 'Sidef::Types::Number::Number') {
            my $repetitions = CORE::int(Sidef::Types::Number::Number::__numify__($$times));

            if ($repetitions < 0) {
                return Sidef::Types::Block::Block->new(code => sub { undef; });
            }

            if (    ref($step) eq 'Sidef::Types::Number::Number'
                and ref($from) eq 'Sidef::Types::Number::Number'
                and ref($$from) eq 'Math::GMPz'
                and ref($$step) eq 'Math::GMPz') {

                $from = $$from;
                $step = $$step;

                if (    ref($to) eq 'Sidef::Types::Number::Number'
                    and ref($$to) eq 'Math::GMPz'
                    and Math::GMPz::Rmpz_fits_slong_p($$to)
                    and Math::GMPz::Rmpz_fits_slong_p($from)
                    and Math::GMPz::Rmpz_fits_slong_p($step)) {

                    $from = Math::GMPz::Rmpz_get_si($from);
                    $step = Math::GMPz::Rmpz_get_si($step);

                    return Sidef::Types::Block::Block->new(
                        code => sub {
                            --$repetitions >= 0 or return undef;

                            if ($from < 8192 and $from >= 0) {
                                my $obj = ($cache[$from] //=
                                           bless(\Math::GMPz::Rmpz_init_set_ui($from), 'Sidef::Types::Number::Number'));
                                $from += $step;
                                return $obj;
                            }

                            if (Math::GMPz::get_refcnt($$Sidef::Types::Number::Number::MPZ) > 1) {
                                $Sidef::Types::Number::Number::MPZ =
                                  bless(\Math::GMPz::Rmpz_init_set_si($from), 'Sidef::Types::Number::Number');
                            }
                            else {
                                Math::GMPz::Rmpz_set_si($$Sidef::Types::Number::Number::MPZ, $from);
                            }

                            $from += $step;
                            $Sidef::Types::Number::Number::MPZ;
                        },
                    );
                }

                my $counter_mpz = Math::GMPz::Rmpz_init_set($from);

                return Sidef::Types::Block::Block->new(
                    code => sub {
                        --$repetitions >= 0 or return undef;
                        if (Math::GMPz::get_refcnt($$Sidef::Types::Number::Number::MPZ) > 1) {
                            $Sidef::Types::Number::Number::MPZ =
                              bless(\Math::GMPz::Rmpz_init_set($counter_mpz), 'Sidef::Types::Number::Number');
                        }
                        else {
                            Math::GMPz::Rmpz_set($$Sidef::Types::Number::Number::MPZ, $counter_mpz);
                        }

                        Math::GMPz::Rmpz_add($counter_mpz, $counter_mpz, $step);
                        $Sidef::Types::Number::Number::MPZ;
                    },
                );
            }
        }

        my $asc = ($self->{_asc} //= !!($step->is_pos // return Sidef::Types::Block::Block->new(code => sub { undef; })));

        my $tmp;
        Sidef::Types::Block::Block->new(
            code => sub {
                ($asc ? $from->le($to) : $from->ge($to)) || return undef;
                $tmp  = $from;
                $from = $from->add($step);
                $tmp;
            },
        );
    }

    sub _reduce_by {
        my ($self, $method, $result, $callback) = @_;

        my @list;
        my $count = 0;

        my $iter = $self->iter;

        while (1) {
            push @list, $callback->($iter->run() // last);

            if (++$count > 1e5) {
                $count  = 0;
                $result = $result->$method(splice(@list));
            }
        }

        if (@list) {
            $result = $result->$method(splice(@list));
        }

        $result;
    }

    sub sum_by {
        my ($self, $block) = @_;
        $block //= Sidef::Types::Block::Block::IDENTITY;
        $self->_reduce_by('sum', Sidef::Types::Number::Number::ZERO, sub { $block->run($_[0]) });
    }

    sub sum {
        my ($self, $arg) = @_;

        if (defined($arg)) {
            goto &sum_by;
        }

        # Formula:
        #   sum(x .. y `by` z) = (floor((y - x)/z) + 1) * (z * floor((y - x)/z) + 2*x) / 2

        my ($x, $y, $z) = @{$self}{'from', 'to', 'step'};

        my $n = $y->sub($x)->div($z);

        if ($n->is_neg) {
            return Sidef::Types::Number::Number::ZERO;
        }

        state $two = Sidef::Types::Number::Number::_set_int(2);

        $n = $n->floor;
        $n->inc->mul($z->mul($n)->add($x->mul($two)))->div($two);
    }

    *Σ = \&sum;

    sub avg_by {
        my ($self, $block) = @_;
        $self->sum_by($block)->div($self->len);
    }

    sub avg {
        my ($self, $arg) = @_;

        if (defined($arg)) {
            goto &avg_by;
        }

        $self->sum->div($self->len);
    }

    sub prod_by {
        my ($self, $block) = @_;
        $block //= Sidef::Types::Block::Block::IDENTITY;
        $self->_reduce_by('prod', Sidef::Types::Number::Number::ONE, sub { $block->run($_[0]) });
    }

    sub prod {
        my ($self, $arg) = @_;

        if (defined($arg)) {
            goto &prod_by;
        }

        if (    $self->{step}->is_one
            and $self->{from}->is_one
            and $self->{to}->is_pos) {
            return $self->{to}->factorial;
        }

        Sidef::Types::Number::Number::prod($self->to_list);
    }

    *Π = \&prod;

    sub lcm_by {
        my ($self, $block) = @_;
        $block //= Sidef::Types::Block::Block::IDENTITY;
        $self->_reduce_by('lcm', Sidef::Types::Number::Number::ONE, sub { $block->run($_[0]) });
    }

    sub lcm {
        my ($self, $arg) = @_;

        if (defined($arg)) {
            goto &lcm_by;
        }

        if (    $self->{step}->is_one
            and $self->{from}->is_one
            and $self->{to}->is_pos) {
            return $self->{to}->consecutive_lcm;
        }

        Sidef::Types::Number::Number::lcm($self->to_list);
    }

    sub gcd_by {
        my ($self, $block) = @_;
        $block //= Sidef::Types::Block::Block::IDENTITY;
        $self->_reduce_by('gcd', Sidef::Types::Number::Number::ZERO, sub { $block->run($_[0]) });
    }

    sub gcd {
        my ($self, $arg) = @_;

        if (defined($arg)) {
            goto &gcd_by;
        }

        Sidef::Types::Number::Number::gcd($self->to_list);
    }

    sub bsearch {
        my ($self, $block) = @_;

        if ($self->{step}->is_one) {
            my $left  = Sidef::Types::Number::Number->new($self->{from});
            my $right = Sidef::Types::Number::Number->new($self->{to});
            return Sidef::Types::Number::Number::bsearch($left, $right, $block);
        }

        $self->to_a->bsearch($block);
    }

    sub bsearch_le {
        my ($self, $block) = @_;

        if ($self->{step}->is_one) {
            my $left  = Sidef::Types::Number::Number->new($self->{from});
            my $right = Sidef::Types::Number::Number->new($self->{to});
            return Sidef::Types::Number::Number::bsearch_le($left, $right, $block);
        }

        $self->to_a->bsearch_le($block);
    }

    sub bsearch_ge {
        my ($self, $block) = @_;

        if ($self->{step}->is_one) {
            my $left  = Sidef::Types::Number::Number->new($self->{from});
            my $right = Sidef::Types::Number::Number->new($self->{to});
            return Sidef::Types::Number::Number::bsearch_ge($left, $right, $block);
        }

        $self->to_a->bsearch_ge($block);
    }

    sub primes {
        my ($self) = @_;

        if ($self->{step}->abs->is_one) {

            my $left  = Sidef::Types::Number::Number->new($self->{from});
            my $right = Sidef::Types::Number::Number->new($self->{to});

            if ($self->{step}->is_neg) {
                return Sidef::Types::Number::Number::primes($right, $left)->flip;
            }

            return Sidef::Types::Number::Number::primes($left, $right);
        }

        $self->grep(Sidef::Types::Block::Block->new(code => sub { $_[0]->is_prime }));
    }

    sub squarefree {
        my ($self) = @_;

        if ($self->{step}->abs->is_one) {

            my $left  = Sidef::Types::Number::Number->new($self->{from});
            my $right = Sidef::Types::Number::Number->new($self->{to});

            if ($self->{step}->is_neg) {
                return Sidef::Types::Number::Number::squarefree($right, $left)->flip;
            }

            return Sidef::Types::Number::Number::squarefree($left, $right);
        }

        $self->grep(Sidef::Types::Block::Block->new(code => sub { $_[0]->is_squarefree }));
    }

    sub semiprimes {
        my ($self) = @_;

        if ($self->{step}->abs->is_one) {

            my $left  = Sidef::Types::Number::Number->new($self->{from});
            my $right = Sidef::Types::Number::Number->new($self->{to});

            if ($self->{step}->is_neg) {
                return Sidef::Types::Number::Number::semiprimes($right, $left)->flip;
            }

            return Sidef::Types::Number::Number::semiprimes($left, $right);
        }

        $self->grep(Sidef::Types::Block::Block->new(code => sub { $_[0]->is_semiprime }));
    }

    sub each_prime {
        my ($self, $block) = @_;

        if ($self->{step}->is_one) {

            my $left  = Sidef::Types::Number::Number->new($self->{from});
            my $right = Sidef::Types::Number::Number->new($self->{to});

            Sidef::Types::Number::Number::each_prime($left, $right, $block);
            return $self;
        }

        $self->lazy->grep(Sidef::Types::Block::Block->new(code => sub { $_[0]->is_prime }))->each($block);
        return $self;
    }

    sub each_composite {
        my ($self, $block) = @_;

        if ($self->{step}->is_one) {

            my $left  = Sidef::Types::Number::Number->new($self->{from});
            my $right = Sidef::Types::Number::Number->new($self->{to});

            Sidef::Types::Number::Number::each_composite($left, $right, $block);
            return $self;
        }

        $self->lazy->grep(Sidef::Types::Block::Block->new(code => sub { $_[0]->is_composite }))->each($block);
        return $self;
    }

    sub each_semiprime {
        my ($self, $block) = @_;

        if ($self->{step}->is_one) {

            my $left  = Sidef::Types::Number::Number->new($self->{from});
            my $right = Sidef::Types::Number::Number->new($self->{to});

            Sidef::Types::Number::Number::each_semiprime($left, $right, $block);
            return $self;
        }

        $self->lazy->grep(Sidef::Types::Block::Block->new(code => sub { $_[0]->is_semiprime }))->each($block);
        return $self;
    }

    sub each_squarefree {
        my ($self, $block) = @_;

        if ($self->{step}->is_one) {

            my $left  = Sidef::Types::Number::Number->new($self->{from});
            my $right = Sidef::Types::Number::Number->new($self->{to});

            Sidef::Types::Number::Number::each_squarefree($left, $right, $block);
            return $self;
        }

        $self->lazy->grep(Sidef::Types::Block::Block->new(code => sub { $_[0]->is_squarefree }))->each($block);
        return $self;
    }

    sub each_powerful {
        my ($self, $k, $block) = @_;

        $k = Sidef::Types::Number::Number->new($k);

        if ($self->{step}->is_one) {

            my $left  = Sidef::Types::Number::Number->new($self->{from});
            my $right = Sidef::Types::Number::Number->new($self->{to});

            Sidef::Types::Number::Number::each_powerful($k, $left, $right, $block);
            return $self;
        }

        $self->lazy->grep(Sidef::Types::Block::Block->new(code => sub { $_[0]->is_powerful($k) }))->each($block);
        return $self;
    }

    sub each_almost_prime {
        my ($self, $k, $block) = @_;

        $k = Sidef::Types::Number::Number->new($k);

        if ($self->{step}->is_one) {

            my $left  = Sidef::Types::Number::Number->new($self->{from});
            my $right = Sidef::Types::Number::Number->new($self->{to});

            Sidef::Types::Number::Number::each_almost_prime($k, $left, $right, $block);
            return $self;
        }

        $self->lazy->grep(Sidef::Types::Block::Block->new(code => sub { $_[0]->is_almost_prime($k) }))->each($block);
        return $self;
    }

    sub each_omega_prime {
        my ($self, $k, $block) = @_;

        $k = Sidef::Types::Number::Number->new($k);

        if ($self->{step}->is_one) {

            my $left  = Sidef::Types::Number::Number->new($self->{from});
            my $right = Sidef::Types::Number::Number->new($self->{to});

            Sidef::Types::Number::Number::each_omega_prime($k, $left, $right, $block);
            return $self;
        }

        $self->lazy->grep(Sidef::Types::Block::Block->new(code => sub { $_[0]->is_omega_prime($k) }))->each($block);
        return $self;
    }

    sub each_squarefree_almost_prime {
        my ($self, $k, $block) = @_;

        $k = Sidef::Types::Number::Number->new($k);

        if ($self->{step}->is_one) {

            my $left  = Sidef::Types::Number::Number->new($self->{from});
            my $right = Sidef::Types::Number::Number->new($self->{to});

            Sidef::Types::Number::Number::each_squarefree_almost_prime($k, $left, $right, $block);
            return $self;
        }

        $self->lazy->grep(Sidef::Types::Block::Block->new(code => sub { $_[0]->is_squarefree && $_[0]->is_almost_prime($k) }))
          ->each($block);
        return $self;
    }

    sub dump {
        my ($self) = @_;
        Sidef::Types::String::String->new("$self");
    }

    *to_s   = \&dump;
    *to_str = \&dump;
}

1;
