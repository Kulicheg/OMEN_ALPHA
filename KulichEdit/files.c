SAVING()
{
    char w;
    unsigned q;
    int e;
    unsigned lineN;
    int chrsav;
    AT(60, 1);
    ATRIB(0);
    printf("Saving...      ");
    ATRIB(0);
    CLS();
    q = 79;
    lineN = 0;
    while (q + lineN < WIN_SIZE)
    {
        q = 79;
        w = window[q + lineN];
        while (w == 32)
        {
            q--;
            w = window[q];
        }
        q++;
        for (e = 0; e < q; e++)
        {
            chrsav = window[e + lineN];
            fputc(chrsav, fp1);
        }
        if (chrsav == 0)
        {
            fclose(fp1);
            AT(60, 1);
            ATRIB(7);
            printf("     0000       ");
            ATRIB(0);
            return;
        }

        fputc(13, fp1);
        fputc(10, fp1);
        lineN = lineN + 80;
    }

    AT(60, 1);
    ATRIB(7);
    printf("  EOM REACHED  ");
    ATRIB(0);
    fclose(fp1);
}
