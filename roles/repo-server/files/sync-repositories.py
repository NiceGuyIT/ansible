#!/usr/bin/env python
import subprocess as sp
import os

def main():
	base_dir = '/var/www/html/repos'
	group = 'apache'
	repos = {
		'epel': '{0}/epel/7/x86_64/'.format(base_dir),
		'CentOS-Base': '{0}/centos/7/base/x86_64/'.format(base_dir),
		'CentOS-Updates': '{0}/centos/7/updates/x86_64'.format(base_dir),
		'CentOS-Extras': '{0}/centos/7/extras/x86_64'.format(base_dir),
		'CentOS-Plus': '{0}/centos/7/plus/x86_64'.format(base_dir)
	}

	for repoid, repo_path in repos.items():
		try:
			sync_repositories(repoid, repo_path)
		except sp.CalledProcessError:
			print 'Failed to sync repo {0}'.format(repoid)
		try:
			update_repo(repo_path)
		except sp.CalledProcessError:
			print 'Failed to update repository metadata at {0}'.format(repo_path)

def sync_repositories(repoid, repo_path):
	sp.check_call(['/usr/bin/reposync', '--repoid={0}'.format(repoid), '--download_path={0}'.format(repo_path), '--downloadcomps', '--norepopath'])


def update_repo(repo_path):
	if os.path.isfile('{0}/comps.xml'.format(repo_path)):
		sp.check_call(['/usr/bin/createrepo', '-g', '{0}/comps.xml'.format(repo_path), '--update', repo_path])
	else:
		sp.check_call(['/usr/bin/createrepo', '--update', repo_path])

if __name__ == '__main__':
	main()
