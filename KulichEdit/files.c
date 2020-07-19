SAVING()
{
    unsigned q;
    char w;

    AT(60, 1);
    ATRIB(0);
    printf("Saving...           ");
    ATRIB(0);

    w = window[0];
    q = 0;
    while (w != 0)
    {
        fputc(w, fp1);
        if (w == 13)
        {
            q++;
            fputc(10, fp1);
        }
        q++;
        w = window[q];
        if (q == WIN_SIZE)
        {
            w = 0;
            AT(60, 1);
            ATRIB(0);
            printf("EOM reached         ");
            ATRIB(0);
        }
    }
    fclose(fp1);

    AT(60, 1);
    ATRIB(7);
    printf("                    ");
    ATRIB(0);
}