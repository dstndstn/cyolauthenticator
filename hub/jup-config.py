#import os

## Grant admin users permission to access single-user servers.
#  Users should be properly informed if this is enabled.
c.JupyterHub.admin_access = True

## Set of users that will have admin rights on this JupyterHub.
#
#  Admin users have extra privileges:
#   - Use the admin panel to see list of users logged in
#   - Add / remove users in some authenticators
#   - Restart / halt the hub
#   - Start / stop users' single-user servers
#   - Can access each individual users' single-user server (if configured)
#
#  Admin access should be treated the same way root access is.
#
#  Defaults to an empty set, in which case no user has admin access.
c.Authenticator.admin_users = set(['dstndstn'])


c.JupyterHub.authenticator_class = 'cyolauthenticator.CYOLAuthenticator'
c.JupyterHub.template_paths = ['/jinja/templates']

# eg from https://github.com/GoogleCloudPlatform/gke-jupyter-classroom/blob/master/jupyterhub/jupyterhub_config.py
c.JupyterHub.hub_ip = '0.0.0.0'
# Bind on localhost -- nginx proxies for us
c.JupyterHub.bind_url = 'http://127.0.0.1:8000'

import kubespawner
c.JupyterHub.spawner_class = 'kubespawner.KubeSpawner'
c.KubeSpawner.debug = True
c.KubeSpawner.start_timeout = 300
#c.KubeSpawner.http_timeout = 90

import pwd
def get_kube_uid(spawner):
    print('Hello, I am get_kube_uid() with spawner', spawner)
    print('spawner.user is', spawner.user)
    print('spawner.user.name is', spawner.user.name)
    print('spawner.user.id is', spawner.user.id)
    uid = pwd.getpwnam(spawner.user.name).pw_uid
    print('pwd uid:', uid)
    return uid

def get_kube_gid(spawner):
    return pwd.getpwnam(spawner.user.name).pw_gid

c.KubeSpawner.uid = get_kube_uid
c.KubeSpawner.gid = get_kube_gid

c.KubeSpawner.image_pull_policy = 'Always'
c.KubeSpawner.volumes = [
    dict(name='nfs2', persistentVolumeClaim=dict(claimName='nfs2')),
]
c.KubeSpawner.volume_mounts = [
    dict(name='nfs2', mountPath='/nfs/home'),
]

# c.KubeSpawner.uid = int, callable -- user to run container as.
#     callable: takes KubeSpawner, returns int.
# c.KubeSpawner.gid = int, callable
# c.KubeSpawner.volumes?
#c.KubeSpawner.volume_mounts, etc

c.KubeSpawner.profile_list = [
    # {
    #     'display_name': 'Jupyter notebook container',
    #     'default': True,
    #     'kubespawner_override': {
    #         'image': 'dstndstn/cyol-singleuser',
    #         'cpu_guarantee': 0.5,
    #         'mem_guarantee': '2G',
    #         'extra_resource_guarantees': {'nvidia.com/gpu': '1'},
    #         'cpu_limit': 0.5,
    #         'mem_limit': '2G',
    #         'extra_resource_limits': {'nvidia.com/gpu': '1'},
    #         'tolerations': [{
    #                      'key': 'nvidia.com/gpu',
    #                      'operator': 'Exists',
    #                      'effect': 'NoSchedule'
    #         }],
    #     },
    # },
    {
        'display_name': 'Spack-based container for Einstein Toolkit',
        'kubespawner_override': {
            'image': 'stevenrbrandt/etworkshop',
            'cpu_guarantee': 0.25,
            'mem_guarantee': '2G',
            'extra_resource_guarantees': {'nvidia.com/gpu': '1'},
            'cpu_limit': 2,
            'mem_limit': '4G',
            'extra_resource_limits': {'nvidia.com/gpu': '1'},
            'tolerations': [{
                         'key': 'nvidia.com/gpu',
                         'operator': 'Exists',
                         'effect': 'NoSchedule'
            }],
        },
    },
    {
        'display_name': 'Original Tutorial Server',
        'kubespawner_override': {
            'image': 'einsteintoolkit/et-workshop',
            'cpu_guarantee': 0.25,
            'mem_guarantee': '2G',
            'extra_resource_guarantees': {'nvidia.com/gpu': '0'},
            'cpu_limit': 2,
            'mem_limit': '4G',
            'extra_resource_limits': {'nvidia.com/gpu': '0'},
            'tolerations': [{
                         'key': 'nvidia.com/gpu',
                         'operator': 'Exists',
                         'effect': 'NoSchedule'
            }],
        },
    },
    
]

# https://github.com/nteract/hydrogen/issues/922
c.NotebookApp.token = 'super$ecret'

# Uncomment if needed
#c.JupyterHub.base_url = '/somename/'
