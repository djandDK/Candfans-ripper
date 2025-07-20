function download-candfans {
    param (
        # The destination to place the files, the downloader will create a folder for the profile you are downloading itself
        [Parameter(Mandatory=$true)]
        [string]$path = "<full path to the destination you want the folder and files placed into>",
        # found in the profile url, in this example: https://candfans.jp/hioRIN the user_code would be hioRIN, so just the part after the slash.
        [Parameter(Mandatory=$true)]
        [string]$user = "hioRIN",
        # The full path to gallery dl unless it's found in the path variable
        [string]$gallerydlPath = "gallery-dl.exe", 
        # The full path to yt-dlp.exe unless it's found in the path variable
        [string]$ytdlpPath = "yt-dlp.exe" 
    )
    
    # Get some information about the profile
    $profile = ((Invoke-WebRequest "https://candfans.jp/api/user/get-users?user_code=$($user)").Content | ConvertFrom-Json).data

    # Create a directory for the profile
    $profilePath = "$($path)\$($profile.user.username) - $($profile.user.user_code) - $($profile.user.id)"
    if (!(Test-Path $profilePath -PathType Container)) {
        New-Item -ItemType Directory -Path $profilePath | Out-Null
    }

    # Download cover image
    $coverImage = "https://image.candfans.jp$($profile.user.profile_cover_img)"
    $coverImagePath = "$($profilePath)\profile_cover_img$([System.IO.Path]::GetExtension($coverImage))"
    if (!(Test-Path $coverImagePath -PathType Leaf)) {
        Invoke-WebRequest $coverImage -OutFile $coverImagePath
    }

    # Download profile image
    $profileImage = "https://image.candfans.jp$($profile.user.profile_img)"
    $profileImagePath = "$($profilePath)\profile_img$([System.IO.Path]::GetExtension($profileImage))"
    if (!(Test-Path $profileImagePath -PathType Leaf)) {
        Invoke-WebRequest $profileImage -OutFile $profileImagePath
    }

    # Download profile text
    $profileText = $profile.user.profile_text
    $profileTextPath = "$($profilePath)\profile_text.txt"
    if (!(Test-Path $profileTextPath -PathType Leaf)) {
        $profileText | Set-Content $profileTextPath -Encoding UTF8
    }

    # We will just rip post type 1 which is included in the subcription, type 2 are the posts that are paid individually.
    # Get the number of posts, we will use this to display progress in some form.
    $contentCount = ((Invoke-WebRequest "https://candfans.jp/api/v3/timeline/content-length?user_id=$($profile.user.id)&post_type%5B%5D=1").Content | ConvertFrom-Json)

    $i = 0
    $p = 0
    do {
        $i++

        # Pull a list of 25 posts at a time and then loop over them (Can pull more if needed, but the site slows down a lot and it might cause the admins to be aware of the ripping)
        $posts = ((Invoke-WebRequest "https://candfans.jp/api/contents/get-timeline?user_id=$($profile.user.id)&sort_order=old&post_type[]=1&record=25&page=$($i)").Content | ConvertFrom-Json).data
        $posts | ForEach-Object {
            $p++
            write-host "Currently working on post $($p)/$($contentCount.content_length)"
            
            # Get more detailed information about the current post
            $post = ((Invoke-WebRequest "https://candfans.jp/api/contents/get-timeline/$($_.post_id)").Content | ConvertFrom-Json).data

            $date = $post.post.post_date -replace ":","."

            switch ($post.post.contents_type) {
                0 {
                    # Text post

                    # Create a directory for the Text posts
                    $textsPath = "$($profilePath)\Text"
                    if (!(Test-Path $textsPath -PathType Container)) {
                        New-Item -ItemType Directory -Path $textsPath | Out-Null
                    }

                    # Create a directory for the Image set
                    $postPath = "$($textsPath)\$($date) - $($post.post.post_id) - " + ($($post.post.title).replace("`n"," ").replace("`r"," ").Trim() -replace '[\\/:*?"<>|]', '_')
                    if (!(Test-Path $postPath -PathType Container)) {
                        New-Item -ItemType Directory -Path $postPath | Out-Null
                    }
                }
                1 {
                    # Image set

                    # Create a directory for the Image sets
                    $imagesPath = "$($profilePath)\Images"
                    if (!(Test-Path $imagesPath -PathType Container)) {
                        New-Item -ItemType Directory -Path $imagesPath | Out-Null
                    }

                    # Create a directory for the Image set
                    $postPath = "$($imagesPath)\$($date) - $($post.post.post_id) - " + ($($post.post.title).replace("`n"," ").replace("`r"," ").Trim() -replace '[\\/:*?"<>|]', '_')
                    if (!(Test-Path $postPath -PathType Container)) {
                        New-Item -ItemType Directory -Path $postPath | Out-Null
                    }

                    # Download images
                    $posts = $post.post.post_attachments
                    $posts | ForEach-Object {
                        $imagePath = "$($postPath)"
                        $imageUrl = "https://image.candfans.jp/user/$($profile.user.id)/post/$($_.post_id)/$($_.default_path)"
                        if (!(Test-Path $imagePath -PathType Leaf)) {
                            &$gallerydlPath --cookies-from-browser Firefox --destination $imagePath $imageUrl
                        }
                    }
                }
                2 {
                    # Video

                    # Create a directory for the Videos
                    $videosPath = "$($profilePath)\Videos"
                    if (!(Test-Path $videosPath -PathType Container)) {
                        New-Item -ItemType Directory -Path $videosPath | Out-Null
                    }

                    # Create a directory for the Video
                    $postPath = "$($videosPath)\$($date) - $($post.post.post_id) - " + ($($post.post.title).replace("`n"," ").replace("`r"," ").Trim() -replace '[\\/:*?"<>|]', '_')
                    if (!(Test-Path $postPath -PathType Container)) {
                        New-Item -ItemType Directory -Path $postPath | Out-Null

                        # Download video
                        $posts = $post.post.post_attachments
                        $posts | ForEach-Object {
                            Push-Location $postPath
                            &$ytdlpPath -q --cookies-from-browser Firefox --output "$([System.IO.Path]::GetFileNameWithoutExtension($_.default_path)).%(ext)s" "https://video.candfans.jp/user/$($profile.user.id)/post/$($_.post_id)/$($posts.default_path)"
                            Pop-Location
                        }
                    }
                }
                3 {
                    # Audio clip

                    # Create a directory for the Audio clips
                    $audioPath = "$($profilePath)\Audio"
                    if (!(Test-Path $audioPath -PathType Container)) {
                        New-Item -ItemType Directory -Path $audioPath | Out-Null
                    }

                    # Create a directory for the Audio clip
                    $postPath = "$($audioPath)\$($date) - $($post.post.post_id) - " + ($($post.post.title).replace("`n"," ").replace("`r"," ").Trim() -replace '[\\/:*?"<>|]', '_')
                    if (!(Test-Path $postPath -PathType Container)) {
                        New-Item -ItemType Directory -Path $postPath | Out-Null
                    }

                    write-host "We have found a piece of content that is an audio clip, there's no handling of this" -ForegroundColor Red
                    $post.post.post_attachments
                }
                default {
                    write-host "We have found an unknown content type" -ForegroundColor Red
                    $post.post
                }
            }

            # Download extra information related to the post

            # Save the json output in case we need it later
            $post | ConvertTo-Json -Depth 99 | Out-File "$($postPath)\post.json"

            # Download thumbnail image if there is one
            if ($post.post.thumbnail_file) {
                write-host "Thumbnail: $($post.post.thumbnail_file)" -ForegroundColor Green
                <#$profileImage = "https://image.candfans.jp$($profile.user.profile_img)"
                $profileImagePath = "$($profilePath)\profile_img$([System.IO.Path]::GetExtension($profileImage))"
                if (!(Test-Path $profileImagePath -PathType Leaf)) {
                    Invoke-WebRequest $profileImage -OutFile $profileImagePath
                }#>
            }

            # Download post description
            $postText = $post.post.contents_text
            $postTextPath = "$($postPath)\desc.txt"
            if (!(Test-Path $postTextPath -PathType Leaf)) {
                $postText | Set-Content $postTextPath -Encoding UTF8
            }
        }
    } while ($posts)
}
