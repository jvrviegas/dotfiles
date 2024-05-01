### Backup DE configurations
Run the command to backup all the desktop configurations
```bash
dconf dump / > name-desktop
```

### Restore the DE configurations
Run the command below to restore all the previous configurations
```bash
dconf load / < name-desktop
```

### Reset all the DE configurations
Run the command below to reset all the configurations
```bash
dconf reset -f /
```
