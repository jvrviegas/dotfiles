# ClickUp CLI reference

All commands use:

```bash
~/.pi/agent/skills/clickup/scripts/clickup.js TOOL '{"argument":"value"}'
```

Output is pretty-printed JSON. Errors are JSON on stderr with an `error` and `code`; credentials are never included.

## Authentication and hierarchy

```bash
clickup.js authenticate
clickup.js list_workspaces
clickup.js list_spaces '{"workspace":"123","archived":false}'
clickup.js list_folders '{"space":"456","archived":false}'
clickup.js list_lists '{"folder":"789","space":"456"}'
clickup.js list_lists '{"space":"456"}'
clickup.js list_users '{"workspace":"123","query":"joao"}'
```

- `workspace` accepts `workspace`, `team`, or `teamId`; it may be an ID or an exact case-insensitive Workspace name.
- `list_spaces` requires a Workspace. `list_folders` requires a Space.
- `list_lists` accepts a Folder or Space. A Folder calls `GET /folder/{folder_id}/list`; a Space calls the folderless-list endpoint `GET /space/{space_id}/list`.
- Resource names are resolved only inside their parent scope. Ambiguous matches fail with candidate IDs/names.
- `list_users` reads members included by `GET /team`. Without a Workspace it returns de-duplicated members from all accessible Workspaces.

Statuses are inherited by scope. Supply one target scope; parent arguments may accompany a name (for example, a Folder name needs its Space):

```bash
clickup.js list_task_statuses '{"space":"456"}'
clickup.js list_task_statuses '{"folder":"789","space":"456"}'
clickup.js list_task_statuses '{"list":"101"}'
```

## Tasks

```bash
clickup.js get_task '{"id":"abc123","includeSubtasks":true}'
clickup.js list_tasks '{"list":"101","page":0,"includeClosed":true,"statuses":["to do","in progress"],"orderBy":"updated"}'
clickup.js save_task '{"list":"101","title":"New task","description":"Markdown or plain text","priority":3,"assignees":[183,184],"tags":["bug"],"dueDate":"2026-06-01","startDate":"2026-05-25","timeEstimate":3600000,"parent":"abc123","notifyAll":true}'
clickup.js save_task '{"id":"abc123","status":"in progress","description":"Updated description"}'
clickup.js save_task '{"id":"abc123","tags":["bug","urgent"]}'
clickup.js delete_task '{"id":"abc123"}'
```

`save_task` creates when `id`/`task`/`taskId` is absent and updates when one is supplied. Creation requires `list` or `listId` and `name` or `title`; `title` maps to ClickUp `name`. Supported save fields are `name`/`title`, `description`, `status`, `priority`, `assignee`/`assignees`, `tags`, `dueDate`, `startDate`, `parent`, `timeEstimate`, and create-only `notifyAll`. ISO dates are converted to ClickUp epoch milliseconds. Multiple assignees are retained. On update, assignees are added using ClickUp's native `{add:[...]}` shape; tags are synchronized through the task-tag endpoints.

`list_tasks` preserves ClickUp's `{tasks,last_page}` pagination metadata. Supported filters include `page`, `archived`, `includeMarkdownDescription`, `orderBy`, `reverse`, `subtasks`, `includeClosed`, `includeTiml`, `statuses`, `assignees`, `watchers`, `tags`, `dueDateGt/Lt`, `dateCreatedGt/Lt`, `dateUpdatedGt/Lt`, `dateDoneGt/Lt`, `customFields`, `customField`, and `customItems`.

For a custom task ID, pass the Workspace because ClickUp requires `custom_task_ids=true` plus `team_id`:

```bash
clickup.js get_task_by_custom_id '{"customTaskId":"CU-42","workspace":"123"}'
clickup.js get_task '{"id":"CU-42","workspace":"123","customTaskIds":true}'
```

## Comments and metadata

```bash
clickup.js list_task_comments '{"task":"abc123"}'
clickup.js list_task_comments '{"task":"abc123","start":1710000000000,"startId":"comment-id"}'
clickup.js save_task_comment '{"task":"abc123","body":"Status update"}'
clickup.js save_task_comment '{"task":"abc123","comment":"Notify me","notifyAll":true}'
clickup.js list_task_tags '{"space":"456"}'
clickup.js list_custom_fields '{"list":"101","includeAppliedObjects":true}'
clickup.js set_custom_field_value '{"task":"abc123","fieldId":"field-uuid","value":"High"}'
```

Task comment pagination requires both `start` and `startId`, using the last comment's `date` and `id`. Tags are scoped to a Space. Custom Fields are scoped to a List; `fieldId` is retained exactly and values are sent as ClickUp-native JSON. Custom Fields must be applicable to the task's current custom task type. `set_custom_field_value` also accepts an explicit object in `body` or `valueOptions` for date fields.

Task-target commands accept `id`, `task`, or `taskId` (the custom-ID command also accepts `customTaskId`). Custom task ID query parameters are supported by task comments, custom-field writes, updates, and deletes when `customTaskIds:true` and a Workspace are supplied.
