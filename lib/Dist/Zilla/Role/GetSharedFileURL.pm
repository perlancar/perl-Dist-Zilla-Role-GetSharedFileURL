package Dist::Zilla::Role::GetSharedFileURL;

# AUTHORITY
# DATE
# DIST
# VERSION

use 5.010001;
use namespace::autoclean;
use Moose::Role;
with 'Dist::Zilla::Role::ModuleMetadata';

use URI::Escape::Path;

sub get_shared_file_url {
    my ($self, $hosting, $path) = @_;

    # remove leading slashes
    $path =~ s!\A/+!!;

    my ($authority, $dist_name, $dist_version);
    my ($github_user, $github_repo);
    my ($gitlab_user, $gitlab_proj);
    my ($bitbucket_user, $bitbucket_repo);

    my $url;
    if ($hosting eq 'metacpan') {

        $authority = $self->zilla->distmeta->{x_authority};
        $self->$self->log_fatal(["Distribution doesn't have x_authority metadata"]) unless $authority;
        $self->$self->log_fatal(["x_authority is not cpan:"]) unless $authority =~ s/^cpan://;
        $dist_name = $self->zilla->name;
        $dist_version = $self->zilla->version;

        $url = sprintf(
            "https://st.aticpan.org/source/%s/%s-%s/%s",
            $authority,
            $dist_name,
            $dist_version,
            uri_escape($path),
        );

    } elsif ($hosting eq 'github' || $hosting eq 'gitlab' || $hosting eq 'bitbucket') {

        my $resources = $self->zilla->distmeta->{resources};
        $self->log_fatal(["Distribution doesn't have resources metadata"]) unless $resources;
        $self->log_fatal(["Distribution resources metadata doesn't have repository"]) unless $resources->{repository};
        $self->log_fatal(["Repository in distribution resources metadata is not a hash"]) unless ref($resources->{repository}) eq 'HASH';
        my $type = $resources->{repository}{type};
        $self->log_fatal(["Repository in distribution resources metadata doesn't have type"]) unless $type;
        my $url = $resources->{repository}{url};
        $self->log_fatal(["Repository in distribution resources metadata doesn't have url"]) unless $url;
        if ($hosting eq 'github') {
            $self->log_fatal(["Repository type is not git"]) unless $type eq 'git';
            $self->log_fatal(["Repository URL is not github"]) unless ($github_user, $github_repo) = $url =~ m!github\.com/([^/]+)/([^/]+)\.git!;
        } elsif ($hosting eq 'gitlab') {
            $self->log_fatal(["Repository type is not git"]) unless $type eq 'git';
            $self->log_fatal(["Repository URL is not gitlab"]) unless ($gitlab_user, $gitlab_proj) = $url =~ m!gitlab\.com/([^/]+)/([^/]+)\.git!;
        } elsif ($hosting eq 'bitbucket') {
            $self->log_fatal(["Repository type is not git (mercurial not yet supported)"]) unless $type eq 'git';
            $self->log_fatal(["Repository URL is not bitbucket"]) unless ($bitbucket_user, $bitbucket_repo) = $url =~ m!bitbucket\.org/([^/]+)/([^/]+)\.git!;
        }

        if ($hosting eq 'github') {
            $url = sprintf(
                "https://raw.githubusercontent.com/%s/%s/master/%s",
                $github_user,
                $github_repo,
                uri_escape($path),
            );
        } elsif () {
            $url = sprintf(
                "https://gitlab.com/%s/%s/raw/master/%s",
                $gitlab_user,
                $gitlab_proj,
                uri_escape($path),
            );
        } else { # bitbucket
            $url = sprintf(
                "https://bytebucket.org/%s/%s/raw/master/%s",
                $bitbucket_user,
                $bitbucket_repo,
                uri_escape($path),
            );
        }

    } else {
        $self->log_fatal(["Unknown hosting value '%s'", $hosting]);
    }

    return $url;
}

1;
# ABSTRACT: Get URL to a shared file

=head1 PROVIDED METHODS

=head2 get_shared_file_url

Usage:

 my $url = $obj->get_shared_file_url($hosting, $path);

Example:

 my $url = $obj->get_shared_file_url('metacpan', 'image1.jpg');      # =>
 my $url = $obj->get_shared_file_url('github', 'subdir/file1.html'); # =>

Known hosting:

=over

=item * metacpan

=item * github

=item * gitlab

=item * bitbucket

=back


=head1 SEE ALSO
