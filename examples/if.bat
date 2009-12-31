:begin
@echo off
if not errorlevel 1 ( goto end
    echo bla
)
echo An error occurred during formatting.
:end
echo End of batch program.
