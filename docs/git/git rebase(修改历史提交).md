## 正常流程

	git rebase -i 68598f1d65da0dd3de283cf5ac04bbf17b58d1a1
	修改文件
	git add .
	git commit --amend
	git rebase --continue

## 文件冲突
	git rebase -i 48a55705063291c68208880bbcc7581e3c2e5074
	修改文件
	git add .
	git rebase --continue
	解决冲突
	git add .
	git rebase –continue

*taps*:忘记了流程。。。