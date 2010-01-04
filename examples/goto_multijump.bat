if errorlevel 2 (
    echo 1
    goto three
    echo 2
    goto one
    echo 3
    :two
    echo 4
    goto out
    :one
    echo 5
    goto two
    echo 6
    :four
    echo 7
    :three
    goto four
    echo 8
)
echo "hey"
echo ho
:out
