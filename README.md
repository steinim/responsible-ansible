Install Ansible
=============
Mac:

```brew install ansible```

```sudo easy_install pip```

```sudo pip install paramiko PyYAML jinja2```

Other:
http://www.ansibleworks.com/docs/intro_installation.html

More:
http://www.ansibleworks.com/docs/intro_getting_started.html

Deploy with Ansible
==================
Go to ansible directory.
Run: ```ansible-playbook --ask-sudo-pass deploy.yml```

With parameters: ```ansible-playbook --ask-sudo-pass deploy.yml --extra-var="env=test version=0.1.0-SNAPSHOT"```

Provision with Ansible
=======================
Go to ansible directory.

Run: ```ansible-playbook --ask-sudo-pass provision.yml```
