package Errors::Errors;

##############################################
# Errors module
##############################################
# Last modified: 22.01.2003

use strict;

# ----- Global members (public) for all objects -----
$Errors::Errors::debugging = 0;
$Errors::Errors::sys_last_TERM_obj = '';
$Errors::Errors::sys_last_ALRM_obj = '';
$Errors::Errors::sys_sent_content  = 0;
$Errors::Errors::sys_last_ERROR = 0;
$Errors::Errors::sys_exit_called = 0;
$Errors::Errors::sys_last_term_invoked = 0;
$Errors::Errors::sys_last_alrm_invoked = 0;

BEGIN
 {
  use vars qw($VERSION @ISA @EXPORT);
  $VERSION = "1.02";
  @ISA = qw(Exporter);
  @EXPORT = qw();
 }

sub AUTOLOAD
{
 my $self = shift;
 my $type = ref($self) or die "$self is not an object";
 my $name = $Errors::Errors::AUTOLOAD;
 $name =~ s/.*://;   # Strip fully-qualified portion
 $name = lc($name);
 unless (exists $self->{__subs}->{$name})
   {
    print "Can't access '$name' field in class $type";
    exit;
   }
my $ref =  $self->{__subs}->{$name};
if(ref($ref)) { &$ref($self,@_); }
}

sub new
{ 
 my $proto = shift;
 my $class = ref($proto) || $proto;
 my $self = {};
 
 my %inp = @_;

 $self->{'error'} = 0;
 $self->{'content'} = $inp{'content'} || 1;
 $Errors::Errors::sys_sent_content = $self->{'content'};
 $self->{'context'} = $ENV{SCRIPT_NAME} eq '' ? 'console' : 'browser';
 $self->{'__subs'} = {};
 $self->{'__errors'} = {};
 $self->{'__objects'} = {};
 $self->{'__counters'} = {};
 $self->{'__subs'}->{'header'}  = \&__default_header;
 $self->{'__subs'}->{'onerror'} = \&__default;
 $self->{'__subs'}->{'onexit'}  = \&__default;
 $self->{'__subs'}->{'onterm'}  = \&__default;
 $self->{'__subs'}->{'ontimeout'}  = \&__default;
 $self->{'__counters'}->{'exit'} = 0;
 $self->{'__counters'}->{'die'} = 0;

 bless($self,$class);
 return($self);
}

sub _set_val_Errors
{
 my $self = shift(@_);
 my $name = shift(@_);
 my @params = @_;
 if(defined($_[0]))
  {
   my $code = '$self->{'."'$name'".'} = $_[0];';
   eval $code;
   return($_[0]);
  }
 else
  {
   my $code = '$code = $self->{'."'$name'".'};';
   eval $code;
   return($code);
  }
}

sub content
{
 my $self = shift(@_);
 my $val  = shift(@_);
 $self->_set_val_Errors('content', $val); 
 $Errors::Errors::sys_sent_content = $val;
} 

sub __default {return 1;}
sub __default_header
{
 if(!$Errors::Errors::sys_sent_content)
  {
   print "Content-type: text/html\n\n";
  }
}

sub __default_SIGNALS
{
  if($Errors::Errors::sys_last_term_invoked == 1) {return(0);}  # Function already invoked! Can't proceed that request!
  $Errors::Errors::sys_last_term_invoked = 1;
  my $how = shift;
  my $self = $Errors::Errors::sys_last_TERM_obj;
  my $sub;
  my $hashref = $self->{'__errors'};
  foreach $sub (keys %$hashref)
   {
    my $ref = $hashref->{$sub}->{'onterm'};
    if(ref($ref)) { &$ref($self,('type'=>'term','name'=>$sub,'signal'=>$how)); }
   }
  my $ref = $self->{'__subs'}->{'onterm'};
  if(ref($ref)) { &$ref($self,('type'=>'term','name'=>'','signal'=>$how)); }
  $Errors::Errors::sys_last_term_invoked = 0;     # Done..it's now safe to make errors ;-)
}

sub __default_SIGNALS_TERM { &Errors::Errors::__default_SIGNALS('term'); }
sub __default_SIGNALS_QUIT { &Errors::Errors::__default_SIGNALS('quit'); }
sub __default_SIGNALS_PIPE { &Errors::Errors::__default_SIGNALS('pipe'); }
sub __default_SIGNALS_STOP { &Errors::Errors::__default_SIGNALS('stop'); }
sub __default_SIGNALS_HUP  { &Errors::Errors::__default_SIGNALS('hup'); }
sub __default_SIGNALS_INT  { &Errors::Errors::__default_SIGNALS('int'); }

sub __default_ALRM
{
  if($Errors::Errors::sys_last_alrm_invoked == 1) {return(0);}
  $Errors::Errors::sys_last_alrm_invoked = 1;
  my $self = $Errors::Errors::sys_last_ALRM_obj;
  my $sub;
  my $hashref = $self->{'__errors'};
  foreach $sub (keys %$hashref)
   {
    my $ref = $hashref->{$sub}->{'ontimeout'};
    if(ref($ref)) { &$ref($self,('type'=>'term','name'=>$sub,'signal'=>'alrm')); }
   }
  my $ref = $self->{'__subs'}->{'ontimeout'};
  if(ref($ref)) { &$ref($self,('type'=>'term','name'=>'','signal'=>'alrm')); }
  $Errors::Errors::sys_last_alrm_invoked = 0;
}

sub install
{
 my $self = shift;
 my $name  = shift;
 my $subref = shift;
 my $sub  = shift;
 $name = lc($name);
 $sub  = lc($sub);

 if($sub eq '')
  {
   if($name eq 'onterm')
    {
     $SIG{'TERM'} = \&__default_SIGNALS_TERM;
     $SIG{'QUIT'} = \&__default_SIGNALS_QUIT;
     $SIG{'PIPE'} = \&__default_SIGNALS_PIPE;
     $SIG{'STOP'} = \&__default_SIGNALS_STOP;
     $SIG{'HUP'}  = \&__default_SIGNALS_HUP;
     $SIG{'INT'}  = \&__default_SIGNALS_INT;
     $Errors::Errors::sys_last_TERM_obj = $self;
    }
   if($name eq 'ontimeout')
    {
     $SIG{'ALRM'} = \&__default_ALRM;
     $Errors::Errors::sys_last_ALRM_obj = $self;
    }
   $self->{'__subs'}->{$name} = $subref;
  }
 else
  {
   $self->{'__errors'}->{$sub}->{$name} = $subref;
  }
 return(1);
}

sub uninstall
{
 my $self = shift;
 my $name  = shift;
 my $sub  = shift;
 $name = lc($name);
 $sub  = lc($sub);
 
 if($sub eq '')
  {
   if($name eq 'onterm')
    {
     $SIG{'TERM'} = \&__default_SIGNALS_TERM;
     $SIG{'QUIT'} = \&__default_SIGNALS_QUIT;
     $SIG{'PIPE'} = \&__default_SIGNALS_PIPE;
     $SIG{'STOP'} = \&__default_SIGNALS_STOP;
     $SIG{'HUP'}  = \&__default_SIGNALS_HUP;
     $SIG{'INT'}  = \&__default_SIGNALS_INT;
    }
   if($name eq 'ontimeout')
    {
     $SIG{'ALRM'} = \&__default_ALRM;
    }
   $self->{'__subs'}->{$name} = undef;
  }
 else
  {
   $self->{'__errors'}->{$sub}->{$name} = undef;
  }
 return(1);
}

sub print
{
 my $self = shift;
 print @_;
}

sub attach
{
 my $self = shift;
 my $name  = shift;
 $name = lc($name);
 $self->{'__errors'}->{$name} = {
 	'error' => 0,
 	'onerror' => \&__default,
        'onexit'  => \&__default,
        'onterm'  => \&__default,
        'ontimeout'  => \&__default,
        };
 $self->{'__objects'}->{$name} = '';
 return(1);
}

sub attach_object
{
 my $self = shift;
 my $name  = shift;
 my $objref = shift;
 $name = lc($name);
 
 if($self->{'__errors'}->{$name})
   {
    $self->{'__objects'}->{$name} = $objref;
   }
 return(1);
}

sub fetch_object
{
 my $self = shift;
 my $name  = shift;
 $name = lc($name);
 
 if($self->{'__errors'}->{$name})
   {
    return($self->{'__objects'}->{$name});
   }
 return(undef);
}

sub detach_object
{
 my $self = shift;
 my $name  = shift;
 $name = lc($name);
 
 if($self->{'__errors'}->{$name})
   {
    $self->{'__objects'}->{$name} = undef;
   }
 return(1);
}

sub detach
{
 my $self = shift;
 my $name  = shift;
 $name = lc($name);
 $self->{'__errors'}->{$name} = undef;
 $self->{'__objects'}->{$name} = undef;
 return(1);
}

sub error
{
  my $self  = shift;
  my $value = shift;
  my $name  = shift;
  my @d = @_;
  my @res = ();
  my $sub;
  if($name eq '')
   {
    @res = $self->_set_val_Errors('error', $value);
    $Errors::Errors::sys_last_ERROR = $value;
   }
  else
   {
    my $hashref = $self->{'__errors'};
    if(defined($value))
     {
      $hashref->{$name}->{'error'} = $value;
      $Errors::Errors::sys_last_ERROR = $value;
      @res = ($value);
     }
    else
     {
      @res = $hashref->{$name}->{'error'};
     }
   }
  my $hashref = $self->{'__errors'};
  foreach $sub (keys %$hashref)
   {
    my $ref = $hashref->{$sub}->{'onerror'};
    if(ref($ref)) { &$ref($self,('type'=>'error','error'=>$value,'name'=>$sub,'to'=>$name,'params'=>\@d)); }
   }
  my $ref = $self->{'__subs'}->{'onerror'};
  if(ref($ref)) { &$ref($self,('type'=>'error','error'=>$value,'name'=>'','to'=>$name,'params'=>\@d)); }
 
  return(@res);
}

sub die
{
  my $self = shift;
  my @d = @_;
  if($self->{'__counters'}->{'die'} == 0)
  {
   $Errors::Errors::sys_exit_called = 1;
   $self->{'__counters'}->{'die'} = 1;
   my $sub;
   my $hashref = $self->{'__errors'};
   foreach $sub (keys %$hashref)
    {
     my $ref = $hashref->{$sub}->{'onexit'};
     if(ref($ref)) { &$ref($self,('type'=>'die','error'=>$Errors::Errors::sys_last_ERROR,'name'=>$sub,'params'=>\@d)); }
    }
   my $ref = $self->{'__subs'}->{'onexit'};
   if(ref($ref)) { &$ref($self,('type'=>'die','error'=>$Errors::Errors::sys_last_ERROR,'name'=>'','params'=>\@d)); }
   die(@_);
  }
  else {return(0);}
}

sub exit
{
  my $self = shift;
  my @d = @_;
  if($self->{'__counters'}->{'exit'} == 0)
  {
   $Errors::Errors::sys_exit_called = 1;
   $self->{'__counters'}->{'exit'} = 1;
   my $sub;
   my $hashref = $self->{'__errors'};
   foreach $sub (keys %$hashref)
    {
     my $ref = $hashref->{$sub}->{'onexit'};
     if(ref($ref)) { &$ref($self,('type'=>'exit','error'=>$Errors::Errors::sys_last_ERROR,'name'=>$sub,'params'=>\@d)); }
    }
   my $ref = $self->{'__subs'}->{'onexit'};
   if(ref($ref)) { &$ref($self,('type'=>'exit','error'=>$Errors::Errors::sys_last_ERROR,'name'=>'','params'=>\@d)); }
   exit(@_);
  }
  else {return(0);}
}

sub DESTROY
{
  my $self = shift;
  my @d = ();
  my $sub;
  my $hashref = $self->{'__errors'};
  if(!$Errors::Errors::sys_exit_called)
   {
    $Errors::Errors::sys_exit_called = 1;
    $self->{'__counters'}->{'die'} = 1;
    $self->{'__counters'}->{'exit'} = 1;
    foreach $sub (keys %$hashref)
     {
      my $ref = $hashref->{$sub}->{'onexit'};
      if(ref($ref)) { &$ref($self,('type'=>'destroy','error'=>$Errors::Errors::sys_last_ERROR,'name'=>$sub,'params'=>\@d)); }
     }
    my $ref = $self->{'__subs'}->{'onexit'};
    if(ref($ref)) { &$ref($self,('type'=>'destroy','error'=>$Errors::Errors::sys_last_ERROR,'name'=>'','params'=>\@d)); }
   }
}

1;
__END__

=head1 NAME

 Errors.pm - Full featured error management module

=head1 DESCRIPTION

=over 4

Error module is created as base "error" catcher module especially for Web

=back

=head1 SYNOPSIS

 use Errors::Errors;
 
 use strict;

 my $obj = Errors::Errors->new();
 
 $obj->content(0);
 $obj->header();

 $obj->attach('xreader');  # Attach sub object (sobject) for error of type 'xreader'.
 $obj->attach('myown');    # Attach sub object for error of type 'myown'.
 
 my $hash = {
	     name=>'July',
	     born_year=>'81',
	    };
 
 $obj->attach_object('xreader',$hash); # Hash ref or object
 
 $obj->install('onTerm',\&custom);            # Install sub for term event.
 $obj->install('onError',\&anysub,'xreader'); # Install sub for xreader sobject which will be called when error occure.
 $obj->install('onExit',\&leave);             # Install sub for exit event.
 $obj->install('onTerm',\&custom,'myown');    # Install additional term sub for 'myown' sobject.
 
 $obj->error(7,'xreader');  # Set error '7' for 'xreader' sobject and force execution of error chain.
 
 #my $h = $obj->fetch_object('xreader');  # Fetch attached object from xreader.
 #$obj->print($h->{name}."\n");
 
 $obj->uninstall('onError','xreader');  # Remove 'xreader' sub from 'error' chain.
 
 $obj->detach_object('xreader'); # Remove attached object from xreader.
 $obj->detach('xreader'); # Remove xreader (and attached objects).
 
 $obj->install('onTimeOut',\&timeout); # Install timeout sub routine.
 eval 'alarm(1);';    # Force alarm after 1s
 sleep(2);            # Wait 2 sec, so alarm will be activeted and 'timeout' chain will be turned.
 #Note: Press CTRL+C to active 'INT' signal ('onTerm' event) before time to flow out.
 
 #$obj->exit();       # Force exit of program.
 #$obj->die();        # Force die of program.
 
 #By default script close 'normally', so 'destroy' chain will be executed.

 sub custom {
  my $obj   = shift;         # 'Errors' object
  my %in    = @_;
  my $type  = $in{'type'};   # Error type: 'term'
  my $name  = $in{'name'};   # Custom error name
  my $sig   = $in{'signal'}; # Invoked signal (term,quit,pipe...)
  # ...blah...blah...
  print "Custom($name)\n";
 }
 sub leave {
  my $obj    = shift;
  my %in     = @_;
  my $type   = $in{'type'};   # Error type: 'exit','die','destroy'
  my $err    = $in{'error'};  # Error value
  my $name   = $in{'name'};   # Custom error name
  my $params = $in{'params'}; # Additional parameters (ref to @)
  my @params = @$params;
  # ...blah...blah...
  print "$type\n";
 }
 sub timeout
 {
  my $obj   = shift;
  my %in    = @_;
  my $type  = $in{'type'};    # Error type: 'term'
  my $name  = $in{'name'};    # Custom error name
  my $sig   = $in{'signal'};  # Invoked signal: 'alrm'
  # ...blah...blah...
  print "Timeout\n";
 }
 sub anysub {
  my $obj    = shift;
  my %in     = @_;
  my $type   = $in{'type'};   # Error type: 'error'
  my $err    = $in{'error'};  # Error message
  my $name   = $in{'name'};   # Custom error name
  my $to     = $in{'to'};     # Message is sent "to"
  my $params = $in{'params'}; # Additional parameters (ref to @)
  my @params = @$params;
  
  
  if($name eq $to && $to eq 'xreader')
   {
    $obj->print ("Error in Xreader!!!\n");  # If error is raised in 'xreader'
    my $h = $obj->fetch_object('xreader');
    $obj->print ($h->{born_year}."\n");
   }
  else
   {
    $obj->print ("Error in ... I don't know ;-)!!!\n");
   }
 }

=head1 AUTHOR

 Julian Lishev - Bulgaria,Sofia
 e-mail: julian@proscriptum.com

 Copyright (c) 2001, Julian Lishev, Sofia 2003
 All rights reserved.

=cut
