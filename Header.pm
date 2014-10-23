package Astro::FITS::Header;

# ---------------------------------------------------------------------------

#+
#  Name:
#    Astro::FITS::Header

#  Purposes:
#    Implements a FITS Header Block

#  Language:
#    Perl object

#  Description:
#    This module wraps a FITS header block as a perl object as a hash
#    containing an array of FITS::Header::Items and a lookup hash for
#    the keywords.  May be tied to a single hash for convenience.

#  Authors:
#    Alasdair Allan (aa@astro.ex.ac.uk)
#    Tim Jenness (t.jenness@jach.hawaii.edu)
#    Craig DeForest (deforest@boulder.swri.edu)

#  Revision:
#     $Id: Header.pm,v 1.15 2002/11/15 02:37:38 timj Exp $

#  Copyright:
#     Copyright (C) 2001-2002 Particle Physics and Astronomy Research Council. 
#     Portions copyright (C) 2002 Southwest Research Institute
#     All Rights Reserved.

#-

# ---------------------------------------------------------------------------

=head1 NAME

Astro::FITS::Header - A FITS header

=head1 SYNOPSIS

  $header = new Astro::FITS::Header( Cards => \@array );

=head1 DESCRIPTION

Stores information about a FITS header block in an object. Takes an hash
with an array reference as an arguement. The array should contain a list
of FITS header cards as input.

=cut

# L O A D   M O D U L E S --------------------------------------------------

use strict;
use vars qw/ $VERSION /;

use Astro::FITS::Header::Item;

'$Revision: 1.15 $ ' =~ /.*:\s(.*)\s\$/ && ($VERSION = $1);

# Operator overloads
use overload '""' => "stringify";

# C O N S T R U C T O R ----------------------------------------------------

=head1 REVISION

$Id: Header.pm,v 1.15 2002/11/15 02:37:38 timj Exp $

=head1 METHODS

=head2 Constructor

=over 4

=item B<new>

Create a new instance from an array of FITS header cards. 

  $item = new Astro::FITS::Header( Cards => \@header );

returns a reference to a Header object.

=cut

sub new {
  my $proto = shift;
  my $class = ref($proto) || $proto;

  # bless the header block into the class
  my $block = bless { HEADER => [],
                      LOOKUP  => {},
		      LASTKEY => undef }, $class;

  # If we have arguments configure the object
  $block->configure( @_ ) if @_;

  return $block;

}

# I T E M ------------------------------------------------------------------

=back

=head2 Accessor Methods

=over 4

=item B<item>

Returns a FITS::Header:Item object referenced by index, C<undef> if it
does not exist.

   $item = $header->item($index);

=cut

sub item {
   my ( $self, $index ) = @_;
   
   return undef unless defined $index;
   return undef unless exists ${$self->{HEADER}}[$index];
   
   # grab and return the Header::Item at $index
   return ${$self->{HEADER}}[$index];
 
}

# K E Y W O R D ------------------------------------------------------------

=item B<keyword>

Returns keyword referenced by index, C<undef> if it does not exist.

   $keyword = $header->keyword($index);

=cut

sub keyword {
   my ( $self, $index ) = @_;
   
   return undef unless defined $index;
   return undef unless exists ${$self->{HEADER}}[$index];
   
   # grab and return the keyword at $index
   return ${$self->{HEADER}}[$index]->keyword();
 
}

# I T E M   B Y   N A M E  -------------------------------------------------

=item B<itembyname>

Returns an array of Header::Items for the requested keyword if called
in list context, or the first matching Header::Item if called in scalar
context. Returns C<undef> if the keyword does not exist.

   @items = $header->itembyname($keyword);
   $item = $header->itembyname($keyword);



=cut

sub itembyname {
   my ( $self, $keyword ) = @_;
            
   # resolve the items from the index array from lookup table
   # grab the index array from the lookup table
   my @index;
   @index = @{${$self->{LOOKUP}}{$keyword}}
         if ( exists ${$self->{LOOKUP}}{$keyword} && 
	      defined ${$self->{LOOKUP}}{$keyword} );
   my @items = map {${$self->{HEADER}}[$_]} @index;
   
   return wantarray ?  @items : @items ? $items[0] : undef;
   
}

# I N D E X   --------------------------------------------------------------

=item B<index>

Returns an array of indices for the requested keyword if called in list
context, or an empty array if it does not exist.

   @index = $header->index($keyword);

If called in scalar context it returns the first item in the array, or
C<undef> if the keyword does not exist.

   $index = $header->index($keyword);

=cut

sub index {
   my ( $self, $keyword ) = @_;
   
   # grab the index array from lookup table
   my @index;
   @index = @{${$self->{LOOKUP}}{$keyword}}
         if ( exists ${$self->{LOOKUP}}{$keyword} && 
	      defined ${$self->{LOOKUP}}{$keyword} );
   
   # return the values array
   return wantarray ? @index : @index ? $index[0] : undef;

}

# V A L U E  ---------------------------------------------------------------

=item B<value>

Returns an array of values for the requested keyword if called
in list context, or an empty array if it does not exist.

   @value = $header->value($keyword);

If called in scalar context it returns the first item in the array, or
C<undef> if the keyword does not exist.

=cut

sub value {
   my ( $self, $keyword ) = @_;
   
   # resolve the values from the index array from lookup table
   my @values =
     map { ${$self->{HEADER}}[$_]->value() } @{${$self->{LOOKUP}}{$keyword}}
         if ( exists ${$self->{LOOKUP}}{$keyword} && 
	      defined ${$self->{LOOKUP}}{$keyword} );

   # loop over the indices and grab the values
   return wantarray ? @values : @values ? $values[0] : undef;
   
}

# C O M M E N T -------------------------------------------------------------

=item B<comment>

Returns an array of comments for the requested keyword if called
in list context, or an empty array if it does not exist.

   @comment = $header->comment($keyword);

If called in scalar context it returns the first item in the array, or
C<undef> if the keyword does not exist.

   $comment = $header->comment($keyword);

=cut

sub comment {
   my ( $self, $keyword ) = @_;
      
   # resolve the comments from the index array from lookup table
   my @comments =
     map { ${$self->{HEADER}}[$_]->comment() } @{${$self->{LOOKUP}}{$keyword}}
         if ( exists ${$self->{LOOKUP}}{$keyword} && 
	      defined ${$self->{LOOKUP}}{$keyword} );
   
   # loop over the indices and grab the comments
   return wantarray ?  @comments : @comments ? $comments[0] : undef;
}

# I N S E R T -------------------------------------------------------------

=item B<insert>

Inserts a FITS header card object at position $index

   $header->insert($index, $item);

the object $item is not copied, multiple inserts of the same object mean 
that future modifications to the one instance of the inserted object will
modify all inserted copies.

=cut

sub insert{
   my ($self, $index, $item) = @_;
   
   # splice the new FITS header card into the array
   splice @{$self->{HEADER}}, $index, 0, $item;
   
   # rebuild the lookup table from the modified header
   $self->_rebuild_lookup();   
   
}


# R E P L A C E -------------------------------------------------------------

=item B<replace>

Replace FITS header card at index $index with card $item

   $card = $header->replace($index, $item);

returns the replaced card.

=cut

sub replace{
   my ($self, $index, $item) = @_;

   # remove the specified item and replace with $item
   my @cards = splice @{$self->{HEADER}}, $index, 1, $item;
   
   # rebuild the lookup table from the modified header
   $self->_rebuild_lookup();
   
   # return removed items
   return wantarray ? @cards : $cards[scalar(@cards)-1];
   
} 
 
# R E M O V E -------------------------------------------------------------

=item B<remove>

Removes a FITS header card object at position $index

   $card = $header->remove($index);

returns the removed card.

=cut

sub remove{
   my ($self, $index) = @_;
   
   # remove the  FITS header card from the array
   my @cards = splice @{$self->{HEADER}}, $index, 1;
   
   # rebuild the lookup table from the modified header
   $self->_rebuild_lookup();
   
   # return removed items
   return wantarray ? @cards : $cards[scalar(@cards)-1];
   
} 

# R E P L A C E  B Y  N A M E ---------------------------------------------

=item B<replacebyname>

Replace FITS header cards with keyword $keyword with card $item

   $card = $header->replacebyname($keyword, $item);  

returns the replaced card.

=cut

sub replacebyname{
   my ($self, $keyword, $item) = @_;
   
   # grab the index array from lookup table
   my @index;
   @index = @{${$self->{LOOKUP}}{$keyword}}
         if ( exists ${$self->{LOOKUP}}{$keyword} && 
	      defined ${$self->{LOOKUP}}{$keyword} );

   # loop over the keywords
   my @cards = map { splice @{$self->{HEADER}}, $_, 1, $item;} @index;

   # rebuild the lookup table from the modified header
   $self->_rebuild_lookup();

   # return removed items
   return wantarray ? @cards : $cards[scalar(@cards)-1];

}

# R E M O V E  B Y   N A M E -----------------------------------------------

=item B<removebyname>

Removes a FITS header card object by name

  @card = $header->removebyname($keyword);

returns the removed cards.

=cut

sub removebyname{
   my ($self, $keyword) = @_;
   
   # grab the index array from lookup table
   my @index;
   @index = @{${$self->{LOOKUP}}{$keyword}}
         if ( exists ${$self->{LOOKUP}}{$keyword} && 
	      defined ${$self->{LOOKUP}}{$keyword} );

   # loop over the keywords
   my @cards = map { splice @{$self->{HEADER}}, $_, 1; } @index;

   # rebuild the lookup table from the modified header
   $self->_rebuild_lookup();
   
   # return removed items
   return wantarray ? @cards : $cards[scalar(@cards)-1];
   
} 

# S P L I C E --------------------------------------------------------------

=item B<splice>

Implements a standard splice operation for FITS headers

   @cards = $header->splice($offset [,$length [, @list]]);
   $last_card = $header->splice($offset [,$length [, @list]]);

Removes the FITS header cards from the header designated by $offset and
$length, and replaces them with @list (if specified) which must be an
array of FITS::Header::Item objects. Returns the cards removed. If offset 
is negative, counts from the end of the FITS header.

=cut

sub splice {
   my $self = shift;
   
   # check for arguments
   my @cards;
   
   if ( scalar(@_) == 0 ) {
      # none
      @cards = splice @{$self->{HEADER}};
      $self->_rebuild_lookup();
      return wantarray ? @cards : $cards[scalar(@cards)-1];
   } elsif ( scalar(@_) == 1 ) {
      # $offset
      my ( $offset ) = @_;
      @cards = splice @{$self->{HEADER}}, $offset;          
      $self->_rebuild_lookup();
      return wantarray ? @cards : $cards[scalar(@cards)-1];
   } elsif ( scalar(@_) == 2 ) {
      # $offset and $length
      my ( $offset, $length ) = @_;
      @cards = splice @{$self->{HEADER}}, $offset, $length;
      $self->_rebuild_lookup();
      return wantarray ? @cards : $cards[scalar(@cards)-1];
   } else {
      # $offset, $length and @list 
      my ( $offset, $length, @list ) = @_;
      @cards = splice @{$self->{HEADER}}, $offset, $length;	
      $self->_rebuild_lookup();
      return wantarray ? @cards : $cards[scalar(@cards)-1];
   }
}

# C A R D S --------------------------------------------------------------

=item B<cards>

Return the object contents as an array of FITS cards.

  @array = $header->cards;

=cut

sub cards {
  my $self = shift;
  return map { "$_" } @{$self->{HEADER}};
}

# A L L I T E M S ---------------------------------------------------------

=item B<allitems>

Returns the header as an array of FITS::Header:Item objects.

   @items = $header->allitems();

=cut

sub allitems {
   my $self = shift;
   return map { $_ } @{$self->{HEADER}};
}

# C O N F I G U R E -------------------------------------------------------

=back

=head2 General Methods

=over 4

=item B<configure>

Configures the object, takes an array of FITS header cards 
or an array of Astro::FITS::Header::Item objects as input.

  $header->configure( Cards => \@array );
  $header->configure( Items => \@array );

Does nothing if the array is not supplied.

=cut

sub configure {
  my $self = shift;

  # return unless we have arguments
  return undef unless @_;

  # grab the argument list
  my %args = @_;

  if (exists $args{Cards} && defined $args{Cards}) {

    # First translate each incoming card into a Item object
    # Any existing cards are removed
    @{$self->{HEADER}} = map {
      new Astro::FITS::Header::Item( Card => $_ );
    } @{ $args{Cards} };

    # Now build the lookup table. There would be a slight efficiency
    # gain to include this in a loop over the cards but prefer
    # to reuse the method for this rather than repeating code
    $self->_rebuild_lookup;

  } elsif (exists $args{Items} && defined $args{Items}){
    # We have an array of Astro::FITS::Header::Items
    @{$self->{HEADER}} = @{ $args{Items} };
    $self->_rebuild_lookup;
  }
}

=item B<freeze>

Method to return a blessed reference to the object so that we can store
ths object on disk using Data::Dumper module.

=cut

sub freeze {
  my $self = shift;
  return bless $self, 'Astro::FITS::Header';
}

# P R I V A T  E   M E T H O D S ------------------------------------------

=back

=head2 Operator Overloading

These operators are overloaded:

=over 4

=item B<"">

When the object is used in a string context the FITS header
block is returned as a single string.

=cut

sub stringify {
  my $self = shift;
  return join("\n", $self->cards )."\n";
}

=back

=head2 Private methods

These methods are for internal use only.

=over 4

=item B<_rebuild_lookup>

Private function used to rebuild the lookup table after modifying the
header block, its easier to do it this way than go through and add one
to the indices of all header cards following the modifed card.

=cut

sub _rebuild_lookup {
   my $self = shift;
   
   # rebuild the lookup table

   # empty the hash 
   $self->{LOOKUP} = { };

   # loop over the existing header array
   for my $j (0 .. $#{$self->{HEADER}}) {

      # grab the keyword from each header item;
      my $key = ${$self->{HEADER}}[$j]->keyword();
            
      # need to account to repeated keywords (e.g. COMMENT)
      unless ( exists ${$self->{LOOKUP}}{$key} &&
               defined ${$self->{LOOKUP}}{$key} ) {
         # new keyword
         ${$self->{LOOKUP}}{$key} = [ $j ];
      } else {     
         # keyword exists, push the current index into the array
         push( @{${$self->{LOOKUP}}{$key}}, $j );
      }   
   }

}

# T I E D   I N T E R F A C E -----------------------------------------------

=back

=head1 TIED INTERFACE

The C<FITS::Header> object can also be tied to a hash: 

   use Astro::FITS::Header;

   $header = new Astro::FITS::Header( Cards => \@array );
   tie %hash, "Astro::FITS::Header", $header   

   $value = $hash{$keyword};
   $hash{$keyword} = $value;

   print "keyword $keyword is present" if exists $hash{$keyword};

   foreach my $key (keys %hash) {
      print "$key = $hash{$key}\n";
   }

=head2 Basic hash translation

Header value type is determined on-the-fly by parsing of the input values.
Anything that parses as a number or a logical is converted to that before
being put in a card (but see below).

There's no way to access the per-card comment fields using the tied interface.

Keywords are CaSE-inNSEnSiTIvE, unlike normal hash keywords.  All
keywords are translated to upper case internally, per the FITS standard.

=head2 Comment cards

Comment cards are a special case because they have no normal value and
their comment field is treated as the hash value.  The keywords
"COMMENT" and "HISTORY" are magic and refer to comment cards; all other
keywords create normal valued cards.  If you don't like that behavior,
don't use the tied interface.

=head2 Multi-card values

Multiline string values are broken up, one card per line in the
string.  Extra-long string values are handled gracefully: they get
split among multiple cards, with a backslash at the end of each card
image.  They're transparently reassembled when you access the data, so
that there is a strong analogy between multiline string values and multiple
cards.  

In general, appending to hash entries that look like strings does what
you think it should.  In particular, comment cards have a newline
appended automatically on FETCH, so that

  $hash{HISTORY} .= "Added multi-line string support";

adds a new HISTORY comment card, while

  $hash{TELESCOP} .= " dome B";

only modifies an existing TELESCOP card.

You can make multi-line values by feeding in newline-delimited
strings, or by assigning from an array ref.  If you ask for a tag that
has a multiline value it's always expanded to a multiline string, even
if you fed in an array ref to start with.  That's by design: multiline
string expansion often acts as though you are getting just the first
value back out, because perl string-to-number conversion stops at the
first newline.  So:

  $hash{CDELT1} = [3,4,5];
  print $hash{CDELT1} + 99,"\n$hash{CDELT1}";

prints "102\n3\n4\n5", and then 

  $hash{CDELT1}++;
  print $hash{CDELT1};

prints "4".

In short, most of the time you get what you want.  But you can always fall
back on the non-tied interface by calling methods like so:

  ((tied $hash)->method())

=head2 Type forcing

Because perl uses behind-the-scenes typing, there is an ambiguity
between strings and numeric and/or logical values: sometimes you want
to create a STRING card whose value could parse as a number or as a
logical value, and perl kindly parses it into a number for you.  To
force string evaluation, feed in a trivial hash array:

  $hash{NUMSTR} = 123;     # generates an INT card containing 123.
  $hash{NUMSTR} = '123';   # generates an INT card containing 123.
  $hash{NUMSTR} = ['123']; # generates a STRING card containing '123'.
  $hash{NUMSTR} = [123];   # generates a STRING card containing '123'.

  $hash{ALPHA} = 'T';      # generates a LOGICAL card containing T. 
  $hash{ALPHA} = ['T'];    # generates a STRING card containing 'T'.

Calls to keys() or each() will, by default, return the keywords in the order 
n which they appear in the header.

=cut

# List of known comment-type fields
%Astro::FITS::Header::COMMENT_FIELD = (
  "COMMENT"=>1,
  "HISTORY"=>1
);


# constructor
sub TIEHASH {
  my ( $class, $obj, %options ) = @_;
  return bless $obj, $class;  
}

# fetch key and value pair

sub FETCH {
  my ($self, $key) = @_;
  
  $key = uc($key);
  my $item = ($self->itembyname($key))[0];
  
  my @values = ((defined $item) && (defined $item->type) && ($item->type eq 'COMMENT')) ?
      $self->comment($key) :
	  $self->value($key);
  
  my $out;
  if($#values <= 0) {
      $out = $values[0];
  } else {
      $out = join("\n",@values);
      $out =~ s/\\\n//gs if (defined($out));
  }
  $out .= "\n" if((defined $item) && (defined $item->type) && ($item->type =~ m/^(COMMENT)$/s));
  return $out;
  
}

# store key and value pair
#
# Multiple-line kludges (CED):
#
#    * Array refs get handled gracefully by being put in as multiple cards.
#
#    * Multiline strings get broken up and put in as multiple cards.
#
#    * Extra-long strings get broken up and put in as multiple cards, with 
#      an extra backslash at the end so that they transparently get put back
#      together upon retrieval.
#

sub STORE {
  my ($self, $keyword, $value) = @_;
    my @values;

  # skip the shenanigans for the normal case
  if( (ref $value) || (length $value > 70) || $value =~ m/\n/s ) {
    my @val;
    # @val gets intermediate breakdowns, @values gets line-by-line breakdowns.
    
    # Change multiline strings into array refs
    if (ref $value eq 'ARRAY') {
      @val = @$value;

    } elsif (ref $value) {
      die "Can't put non-array ref values into a tied FITS header\n";

    } elsif( $value =~ m/\n/s ) {
      @val = split("\n",$value);
      chomp @val;

    } else {
      @val = $value;
    }
    
    # Cut up really long items into multiline strings
    my($val);
    foreach $val(@val) {
      while((length $val) > 70) {
	push(@values,substr($val,0,69)."\\");
	$val = substr($val,69);
      }
      push(@values,$val);
    }
  }   ## End of complicated case
  else {
    @values = $value;
  }
    
  $keyword = uc($keyword);
  my @items = $self->itembyname($keyword);
  
  ## Remove extra items if necessary
  if(scalar(@items) > scalar(@values)) {
    my(@indices) = $self->index($keyword);
    my($i);
    for $i (1..(scalar(@items) - scalar(@values))) {
      $self->remove( $indices[-$i] );
    }
  }
  
  ## Allocate items if necessary
  while(scalar(@items) < scalar(@values)) {

    my $item = new Astro::FITS::Header::Item(Keyword=>$keyword,Value=>undef);
    $item->type('COMMENT') if($Astro::FITS::Header::COMMENT_FIELD{$keyword}
			      || ((defined $items[0]) && 
				  (defined $items[0]->type) &&
				  ($items[0]->type eq 'COMMENT')));

    $self->insert(-1,$item);
    push(@items,$item);
  }
  
  ## Set values or comments
  my($i); 
  for $i(0..$#values) {
    if($Astro::FITS::Header::COMMENT_FIELD{$keyword}) {
      $items[$i]->type('COMMENT');
      $items[$i]->comment($values[$i]);
    } else {
      $items[$i]->type( (($#values > 0) || ref $value) ? 'STRING' : undef);

      $items[$i]->value($values[$i]);
      $items[$i]->type("STRING") if($#values > 0);
    }
  }
}  


# reports whether a key is present in the hash
sub EXISTS {
  my ($self, $keyword) = @_;
  return undef unless exists ${$self->{LOOKUP}}{$keyword};  
}

# deletes a key and value pair
sub DELETE {
  my ($self, $keyword) = @_;
  return $self->removebyname($keyword);
}

# empties the hash
sub CLEAR {
  my $self = shift; 
  $self->{HEADER} = [ ];
  $self->{LOOKUP} = { };
  $self->{LASTKEY} = undef;
  $self->{SEENKEY} = undef;
}

# implements keys() and each()
sub FIRSTKEY {
  my $self = shift;
  $self->{LASTKEY} = 0;
  $self->{SEENKEY} = {};
  return undef unless defined @{$self->{HEADER}};
  return ${$self->{HEADER}}[0]->keyword();
}

# implements keys() and each()
sub NEXTKEY {
  my ($self, $keyword) = @_; 
  return undef if $self->{LASTKEY}+1 == scalar(@{$self->{HEADER}}) ;

  # Skip later lines of multi-line cards...
  my($a);
  do {
    $self->{LASTKEY} += 1;  
    $a = $self->{HEADER}->[$self->{LASTKEY}];
    return undef unless defined $a;
  } while ( $self->{SEENKEY}->{$a->keyword});
  $a = $a->keyword;

  $self->{SEENKEY}->{$a} = 1;
  return $a;
}

# garbage collection
# sub DESTROY { }

# T I M E   A T   T H E   B A R  --------------------------------------------

=head1 COPYRIGHT

Copyright (C) 2001-2002 Particle Physics and Astronomy Research Council
and portions Copyright (C) 2002 Southwest Research Institute.
All Rights Reserved.

This program is free software; you can redistribute it and/or modify
it under the same terms as Perl itself.

=head1 AUTHORS

Alasdair Allan E<lt>aa@astro.ex.ac.ukE<gt>,
Tim Jenness E<lt>t.jenness@jach.hawaii.eduE<gt>,
Craig DeForest E<lt>deforest@boulder.swri.eduE<gt>

=cut

# L A S T  O R D E R S ------------------------------------------------------

1;
