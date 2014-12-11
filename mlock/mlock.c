/*
 * base code found at: 2014 Red Hat, Inc
	Example 2.2. 
    https://access.redhat.com/documentation/en-US/Red_Hat_Enterprise_MRG/1.3/html/Realtime_Reference_Guide/sect-Realtime_Reference_Guide-Memory_allocation-Using_mlock_to_avoid_memory_faults.html

	Modified for FreeBSD by David P. Discher <dpd@dpdtech.com>

*/
#include <stdlib.h>
#include <malloc_np.h>
#include <stdio.h>
#include <sys/types.h>
#include <sys/mman.h>

char *
alloc_workbuf(int size)
{
 char *ptr;

 /* allocate some memory */
 ptr = malloc(size);

 /* return NULL on failure */
 if (ptr == NULL) {
	printf ("Failed to malloc\n");
    return NULL;
 } else {
	printf ("malloc good\n");
 }

 /* lock this buffer into RAM */
/*
 * mlock()
RETURN VALUES
     Upon successful completion, the value 0 is returned; otherwise the
     value -1 is returned and the global variable errno is set to indicate the
     error.
*/
 if (mlock(ptr, size)) {
  printf ( "mlock failed\n");
  free(ptr);
  return NULL;
 }

 printf ( "mlock good\n");
 return ptr;
}

void 
free_workbuf(char *ptr, int size)
{
 /* unlock the address range */
 munlock(ptr, size);

 /* free the memory */
 free(ptr);
}


int 
main ( ) 
{
	char * ptr;
	int size = 4096;

	ptr = alloc_workbuf(size);
	free_workbuf(ptr, size);
	

}

