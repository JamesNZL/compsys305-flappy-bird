# `COMPSYS 305` Flappy Bird

An FPGA implementation of Flappy Bird, played using a PS/2 mouse, DIP switches, and push-buttons on the DE0-CV board.

## Contributing

### Making Progress

1. If you are working locally, `git pull` any upstream changes
2. Create a new feature branch with an appropriate name
	> **Example**  
	> `git switch -c rc-filter`
3. Work on that branch, referencing the **Issue** in commit messages as appropriate
	> **Example**  
	> `git commit -m "feat(rc-filter): add comparator (#IssueId)"`

	> **Warning**  
	> Before you commit, ensure you `git pull`.  
	> After you commit, ensure you `git push`.
4. Once the feature is complete, `git push` your local changes

### Finishing Up

5. Open a [new **Pull Request**](https://github.com/uoa-ece209/ee209-2022-project-team01/compare) into `main` using the Pull Request template that references the `#IssueId` you are closing
	1. Assign yourself to the created **Pull Request**
	2. Request review from the other team members
6. Once all team members have approved the changes, [**squash and merge**](https://docs.github.com/en/pull-requests/collaborating-with-pull-requests/incorporating-changes-from-a-pull-request/about-pull-request-merges#squash-and-merge-your-pull-request-commits) with a commit message that summarises the feature
	> **Example**  
	> `feat(hardware): :sparkles: add rc filter circuit (#IssueId)`
7. Delete the feature branch
8. Mark the [To-Do on Notion](https://www.notion.so/cs209-team-1/a948b12f3eb44f7f975441dbc4a0961d?v=80de9e7a80f149cdbdb50e1694a00174) as `Completed`
