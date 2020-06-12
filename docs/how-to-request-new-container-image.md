# 如何增加新的容器镜像

## 首先请查看已有镜像列表[mirrored-images.txt](../mirror/mirrored-images.txt)。 

## 如果您需要其他镜像, 请您编辑 [required-images.txt](../mirror/required-images.txt) ，这将会在您的GitHub账户中 fork 一个新的分支，之后您可以提交 PR（pull request）。 

![image-request-pr](media/image-request-pr.png)

## 后台管理员 Merge 您的PR会触发 `CodeBuild` 去拉取 `required-images.txt` 中定义的镜像回ECR库。 

![mirror-PR-Merged](media/mirror-PR-Merged.png)

## 拉取过程中，图标会变成`in progress`

![mirror-inprogress](media/mirror-inprogress.png)

## 拉取完后，您可以看到图标从`in progress`变为`passing`
![](https://codebuild.ap-northeast-1.amazonaws.com/badges?uuid=eyJlbmNyeXB0ZWREYXRhIjoicjlSNndlSGg4ZkJPQXF0Z1hIQnJIaFZES2VvN2tmUllKTjNEemJGeDVKZU5UUUt5eWdWT0Jrd0NZc2xweHROZFV1dEdXNmJLOVZmUGF1Tnl3ZmRSd1ZBPSIsIml2UGFyYW1ldGVyU3BlYyI6Ik5rNkxrdTZnR21GLzl4YzkiLCJtYXRlcmlhbFNldFNlcmlhbCI6MX0%3D&branch=master)

![mirror-passing](media/mirror-passing.png)